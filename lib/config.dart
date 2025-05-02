// If backend URL not defined, assume it's one running on the emulator's host
const String BACKEND_URL = String.fromEnvironment('BACKEND_URL', defaultValue: "http://10.0.2.2:8000");