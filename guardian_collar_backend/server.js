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
  cameraUrl: null,
  cameraStatus: "off",
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

app.post("/api/device/status", (req, res) => {
  const {
    activity,
    latitude,
    longitude,
    gpsText,
    safeZoneStatus,
    meowText,
    cameraUrl,
    cameraStatus
  } = req.body;

  latestStatus = {
    activity: activity ?? latestStatus.activity,
    latitude: latitude ?? latestStatus.latitude,
    longitude: longitude ?? latestStatus.longitude,
    gpsText: gpsText ?? latestStatus.gpsText,
    safeZoneStatus: safeZoneStatus ?? latestStatus.safeZoneStatus,
    meowText: meowText ?? latestStatus.meowText,
    cameraUrl: cameraUrl ?? latestStatus.cameraUrl,
    cameraStatus: cameraStatus ?? latestStatus.cameraStatus,
    updatedAt: new Date().toISOString()
  };

  res.json({ success: true, data: latestStatus });
});

app.get("/api/safe-zone", (req, res) => {
  res.json({
    success: true,
    data: safeZone
  });
});

app.post("/api/camera/start", (req, res) => {
  latestCommand = {
    type: "start_camera",
    createdAt: new Date().toISOString()
  };

  latestStatus.cameraStatus = "starting";
  latestStatus.updatedAt = new Date().toISOString();

  res.json({
    success: true,
    command: latestCommand,
    data: latestStatus
  });
});

app.post("/api/camera/stop", (req, res) => {
  latestCommand = {
    type: "stop_camera",
    createdAt: new Date().toISOString()
  };

  latestStatus.cameraStatus = "off";
  latestStatus.updatedAt = new Date().toISOString();

  res.json({
    success: true,
    command: latestCommand,
    data: latestStatus
  });
});

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Guardian Collar API running on ${PORT}`));