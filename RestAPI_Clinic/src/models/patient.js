// src/models/Patient.js
const mongoose = require('mongoose');

const patientSchema = new mongoose.Schema({
  name:         { type: String, required: true },
  birthDate:    { type: Date },
  email:        { type: String, required: true, unique: true },
  phone:        { type: String },
  passwordHash: { type: String }
}, { timestamps: true });

module.exports = mongoose.model('Patient', patientSchema);
