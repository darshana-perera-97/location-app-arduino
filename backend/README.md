# Location App Backend

A Node.js backend API for the Arduino GPS Location Tracking App.

## Features

- **Express.js** server with RESTful API endpoints
- **CORS** enabled for cross-origin requests
- **Location data management** with in-memory storage
- **Device status tracking** for Arduino connection monitoring
- **Static file serving** for the HTML frontend
- **Error handling** and validation

## API Endpoints

### Status Endpoints
- `GET /api/status` - Get device connection status
- `POST /api/device/status` - Update device status

### Location Endpoints
- `GET /api/location` - Get current location
- `POST /api/location` - Update/add new location data
- `GET /api/history` - Get location history
- `DELETE /api/history` - Clear location history

### Web Interface
- `GET /` - Serve the HTML frontend

## Installation

1. Navigate to the backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file (optional):
```bash
PORT=3000
NODE_ENV=development
```

## Running the Server

### Development Mode (with auto-restart):
```bash
npm run dev
```

### Production Mode:
```bash
npm start
```

The server will start on `http://localhost:3000` (or the port specified in your `.env` file).

## API Usage Examples

### Update Location Data
```bash
curl -X POST http://localhost:3000/api/location \
  -H "Content-Type: application/json" \
  -d '{
    "latitude": 40.7128,
    "longitude": -74.0060,
    "altitude": 10.5,
    "speed": 0
  }'
```

### Get Current Location
```bash
curl http://localhost:3000/api/location
```

### Update Device Status
```bash
curl -X POST http://localhost:3000/api/device/status \
  -H "Content-Type: application/json" \
  -d '{
    "connected": true,
    "gpsSignal": "strong"
  }'
```

## Data Structure

### Location Object
```json
{
  "latitude": 40.7128,
  "longitude": -74.0060,
  "altitude": 10.5,
  "speed": 0,
  "timestamp": "2024-01-01T12:00:00.000Z"
}
```

### Device Status Object
```json
{
  "connected": true,
  "lastUpdate": "2024-01-01T12:00:00.000Z",
  "gpsSignal": "strong"
}
```

## Integration with Arduino

This backend is designed to work with Arduino GPS modules. Your Arduino code should:

1. Connect to WiFi
2. Read GPS data
3. Send POST requests to `/api/location` with location data
4. Send POST requests to `/api/device/status` to update connection status

## Dependencies

- **express**: Web framework
- **cors**: Cross-origin resource sharing
- **dotenv**: Environment variable management
- **firebase-admin**: Firebase integration (for future use)
- **moment**: Date/time manipulation

## Development Dependencies

- **nodemon**: Auto-restart during development

## Notes

- Currently uses in-memory storage (data is lost on server restart)
- For production, consider integrating with a database
- Firebase Admin SDK is included for future Firebase integration
- CORS is enabled for all origins (configure appropriately for production)
