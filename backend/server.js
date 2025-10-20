const express = require('express');
const cors = require('cors');
const path = require('path');
const { initializeApp } = require('firebase/app');
const { getDatabase, ref, get, onValue } = require('firebase/database');
require('dotenv').config();

// Import Firebase configuration
const firebaseConfig = require('./config/firebase');

const app = express();
const PORT = process.env.PORT || 3006;

// Initialize Firebase
const firebaseApp = initializeApp(firebaseConfig);
const database = getDatabase(firebaseApp);

// Middleware
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve static files from html folder
app.use(express.static(path.join(__dirname, '../html/index.html')));

// In-memory storage for location data (replace with database in production)
let locationData = {
  currentLocation: null,
  locationHistory: [],
  deviceStatus: {
    connected: false,
    lastUpdate: null,
    gpsSignal: 'weak'
  }
};

// Routes
app.get('/', (req, res) => {
  res.sendFile(path.join(__dirname, '../html/index.html'));
});

// API Routes
app.get('/api/status', (req, res) => {
  res.json({
    success: true,
    data: locationData.deviceStatus
  });
});

app.get('/api/location', (req, res) => {
  res.json({
    success: true,
    data: locationData.currentLocation
  });
});

app.get('/api/history', (req, res) => {
  res.json({
    success: true,
    data: locationData.locationHistory
  });
});

app.post('/api/location', (req, res) => {
  try {
    const { latitude, longitude, altitude, speed, timestamp } = req.body;
    
    // Validate required fields
    if (!latitude || !longitude) {
      return res.status(400).json({
        success: false,
        message: 'Latitude and longitude are required'
      });
    }

    const newLocation = {
      latitude: parseFloat(latitude),
      longitude: parseFloat(longitude),
      altitude: altitude ? parseFloat(altitude) : null,
      speed: speed ? parseFloat(speed) : null,
      timestamp: timestamp || new Date().toISOString()
    };

    // Update current location
    locationData.currentLocation = newLocation;
    
    // Add to history
    locationData.locationHistory.push(newLocation);
    
    // Keep only last 100 locations in history
    if (locationData.locationHistory.length > 100) {
      locationData.locationHistory = locationData.locationHistory.slice(-100);
    }

    // Update device status
    locationData.deviceStatus = {
      connected: true,
      lastUpdate: new Date().toISOString(),
      gpsSignal: 'strong'
    };

    res.json({
      success: true,
      message: 'Location updated successfully',
      data: newLocation
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating location',
      error: error.message
    });
  }
});

app.post('/api/device/status', (req, res) => {
  try {
    const { connected, gpsSignal } = req.body;
    
    locationData.deviceStatus = {
      connected: connected || false,
      lastUpdate: new Date().toISOString(),
      gpsSignal: gpsSignal || 'weak'
    };

    res.json({
      success: true,
      message: 'Device status updated',
      data: locationData.deviceStatus
    });

  } catch (error) {
    res.status(500).json({
      success: false,
      message: 'Error updating device status',
      error: error.message
    });
  }
});

app.delete('/api/history', (req, res) => {
  locationData.locationHistory = [];
  res.json({
    success: true,
    message: 'Location history cleared'
  });
});

// Firebase Realtime Database endpoint
app.get('/api/lastData', async (req, res) => {
  try {
    // Reference to the root of the database
    const dbRef = ref(database);
    
    // Get all data from Firebase
    const snapshot = await get(dbRef);
    
    if (snapshot.exists()) {
      const data = snapshot.val();
      
      // Find the most recent location data
      let lastLocationData = null;
      let lastTimestamp = null;
      
      // Traverse the data to find the latest location entry
      const findLatestLocation = (obj, path = '') => {
        if (typeof obj === 'object' && obj !== null) {
          for (const [key, value] of Object.entries(obj)) {
            const currentPath = path ? `${path}/${key}` : key;
            
            // Check if this looks like location data
            if (value && typeof value === 'object' && 
                (value.latitude !== undefined || value.lat !== undefined) &&
                (value.longitude !== undefined || value.lng !== undefined || value.lon !== undefined)) {
              
              const timestamp = value.timestamp || value.time || value.date || key;
              if (!lastTimestamp || timestamp > lastTimestamp) {
                lastLocationData = {
                  ...value,
                  path: currentPath,
                  timestamp: timestamp
                };
                lastTimestamp = timestamp;
              }
            }
            
            // Recursively search nested objects
            if (typeof value === 'object') {
              findLatestLocation(value, currentPath);
            }
          }
        }
      };
      
      findLatestLocation(data);
      
      res.json({
        success: true,
        message: 'Data loaded from Firebase successfully',
        data: {
          lastLocation: lastLocationData,
          allData: data,
          timestamp: new Date().toISOString()
        }
      });
      
    } else {
      res.json({
        success: true,
        message: 'No data found in Firebase',
        data: {
          lastLocation: null,
          allData: null,
          timestamp: new Date().toISOString()
        }
      });
    }
    
  } catch (error) {
    console.error('Firebase error:', error);
    res.status(500).json({
      success: false,
      message: 'Error loading data from Firebase',
      error: error.message
    });
  }
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: 'Something went wrong!',
    error: process.env.NODE_ENV === 'development' ? err.message : 'Internal server error'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📱 Location App Backend API ready`);
  console.log(`🌐 Access the app at: http://localhost:${PORT}`);
});

module.exports = app;
