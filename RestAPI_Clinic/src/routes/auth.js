// src/routes/auth.js
const express = require('express');
const router = express.Router();
const authCtrl = require('../controllers/auth');
const authJWT = require('../middleware/authJWT');
const role = require('../middleware/role');

// Public: register patient
router.post('/register/patient', authCtrl.registerPatient);
// Admin: register doctor
router.post('/register/doctor', authJWT, role('admin'), authCtrl.registerDoctor);
// Public: login (provide field 'type': 'doctor' or 'patient')
router.post('/login', authCtrl.login);
router.post('/google', authCtrl.google);

module.exports = router;