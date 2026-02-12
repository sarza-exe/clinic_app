// src/controllers/auth.js
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const Doctor = require('../models/doctor');
const Patient = require('../models/patient');
const { OAuth2Client } = require('google-auth-library');

const CLIENT_ID = process.env.GOOGLE_CLIENT_ID; 
const client = new OAuth2Client(CLIENT_ID);

console.log("Patient schema loaded", Patient.schema);

/**
 * POST /auth/google
 * Body: { idToken: string, type: 'doctor' | 'patient' }
 * 
 * - Verify the `idToken` with Google.
 * - Check if email exists in. If not, optionally auto-create a Patient (or reject).
 * - Issue your own JWT: jwt.sign({ id: user._id, role }, JWT_SECRET).
 */
exports.google = async (req, res, next) => {
  try {
    const { idToken, type } = req.body;
    if (!idToken || !type) {
      return res.status(400).json({ error: 'idToken and type required' });
    }

    // 1) Verify the Google ID token
    const ticket = await client.verifyIdToken({
      idToken,
      audience: CLIENT_ID,
    });
    const payload = ticket.getPayload();
    // payload.email_verified, payload.email, payload.name, payload.sub (Google user ID), etc.

    if (!payload || !payload.email_verified) {
      return res.status(401).json({ error: 'Google token not valid or email not verified' });
    }

    const email = payload.email;
    const name  = payload.name;

    // 2) Find or create the user in your DB
    let user;
    let role;
    if (type === 'doctor') {
      // Only existing doctors should sign in via Google; reject if not found
      user = await Doctor.findOne({ email });
      if (!user) {
        return res.status(404).json({ error: 'No doctor account found for that email' });
      }
      role = user.role; // doctor.role could be 'doctor' or 'admin'
    } else {
      // type === 'patient'
      // If patient doesn't exist, you might auto-create one with a random password hash
      user = await Patient.findOne({ email });
      if (!user) {
        // Auto-create a patient record:
        const newPatient = new Patient({
          name: name || 'Unknown', // fallback if name missing
          email,
          phone: '',      // you can leave phone blank
          birthDate: null, 
          passwordHash: '', // no local password (google-only)
        });
        user = await newPatient.save();
      }
      role = 'patient';
    }

    // 3) Issue your own JWT
    const appToken = jwt.sign(
      { id: user._id, role },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );

    return res.json({ token: appToken, role });
  } catch (err) {
    console.error('Error in /auth/google:', err);
    return res.status(500).json({ error: 'Google login failed' });
  }
};

// POST /auth/register/patient
exports.registerPatient = async (req, res, next) => {
  try {
    const { name, birthDate, email, phone, password } = req.body;
    const existing = await Patient.findOne({ email });
    if (existing) return res.status(409).json({ error: 'Email in use' });

    const passwordHash = await bcrypt.hash(password, 10);
    const patient = await Patient.create({ name, birthDate, email, phone, passwordHash });

    const token = jwt.sign(
      { id: patient._id, role: patient.role },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );

    res.status(201).json({ token });
  } catch (err) {
    next(err);
  }
};

// POST /auth/register/doctor  (admin only)
exports.registerDoctor = async (req, res, next) => {
  try {
    const { name, specialty, email, password, role } = req.body;
    const existing = await Doctor.findOne({ email });
    if (existing) return res.status(409).json({ error: 'Email in use' });

    const passwordHash = await bcrypt.hash(password, 10);
    const doctor = await Doctor.create({ name, specialty, email, passwordHash, role });

    const token = jwt.sign(
      { id: doctor._id, role: doctor.role },
      process.env.JWT_SECRET,
      { expiresIn: '8h' }
    );

    res.status(201).json({ token });
  } catch (err) {
    next(err);
  }
};

// POST /auth/login
exports.login = async (req, res, next) => {
  try {
    const { email, password, type } = req.body;
    const Model = type === 'doctor' ? Doctor : Patient;
    const user  = await Model.findOne({ email });
    if (!user) return res.status(400).json({ error: 'Invalid credentials' });

    const isMatch = await bcrypt.compare(password, user.passwordHash);
    if (!isMatch) return res.status(400).json({ error: 'Invalid credentials' });

    // For doctors, use user.role; for patients, force 'patient'
    const role = type === 'doctor' ? user.role : 'patient';

    const token = jwt.sign(
      { id: user._id, role },
      process.env.JWT_SECRET,
      { expiresIn: '1h' }
    );

    // Return both token and role so the client can store it directly if desired
    res.json({ token, role });
  } catch (err) {
    next(err);
  }
};