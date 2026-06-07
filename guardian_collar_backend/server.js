const express = require("express");
const cors = require("cors");

const app = express();
app.use(cors());
app.use(express.json());

let latestStatus = {
  activity: "Waiting for ESP32",
  latitude: null,
  longitude: null,
  gpsText: "Waiting for GPS fix",
  safeZoneStatus: "Not set",
  meowText: "No translation yet",
  updatedAt: null
};

let safeZone = {
  latitude: null,
  longitude: null,
  radius: null,
  updatedAt: null
};

let latestCommand = null;

app.get("/", (req, res) => {
  res.json({ ok: true, app: "Guardian Collar API" });
});

app.post("/api/device/status", (req, res) => {
  const { activity, latitude, longitude, gpsText, safeZoneStatus, meowText } = req.body;

  latestStatus = {
    activity: activity ?? latestStatus.activity,
    latitude: latitude ?? latestStatus.latitude,
    longitude: longitude ?? latestStatus.longitude,
    gpsText: gpsText ?? latestStatus.gpsText,
    safeZoneStatus: safeZoneStatus ?? latestStatus.safeZoneStatus,
    meowText: meowText ?? latestStatus.meowText,
    updatedAt: new Date().toISOString()
  };

  res.json({ success: true, data: latestStatus });
});

app.get("/api/device/status", (req, res) => {
  res.json({ success: true, data: latestStatus });
});

app.post("/api/device/command", (req, res) => {
  const { type, intensity } = req.body;

  latestCommand = {
    type,
    intensity: intensity ?? null,
    createdAt: new Date().toISOString()
  };

  res.json({ success: true, command: latestCommand });
});

app.get("/api/device/command", (req, res) => {
  const command = latestCommand;
  latestCommand = null;
  res.json({ success: true, command });
});

app.post("/api/safe-zone", (req, res) => {
  const { latitude, longitude, radius } = req.body;

  if (latitude == null || longitude == null || radius == null) {
    return res.status(400).json({
      success: false,
      message: "latitude, longitude and radius are required"
    });
  }

  safeZone = {
    latitude,
    longitude,
    radius,
    updatedAt: new Date().toISOString()
  };

  latestStatus.safeZoneStatus = `Set: ${radius}m radius`;
  latestStatus.updatedAt = new Date().toISOString();

  latestCommand = {
    type: "set_safe_zone",
    latitude,
    longitude,
    radius,
    createdAt: new Date().toISOString()
  };

  res.json({
    success: true,
    data: safeZone
  });
});

app.get("/api/safe-zone", (req, res) => {
  res.json({
    success: true,
    data: safeZone
  });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Guardian Collar API running on ${PORT}`));