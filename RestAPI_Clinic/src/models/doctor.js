// src/models/Doctor.js
const mongoose = require('mongoose');

const doctorSchema = new mongoose.Schema({
  name:         { type: String, required: true },
  specialty:    { type: String, required: true },
  email:        { type: String, required: true, unique: true },
  passwordHash: { type: String, required: true },
  role:         { type: String, enum: ['admin','doctor'], default: 'doctor' }
}, { timestamps: true });

module.exports = mongoose.model('Doctor', doctorSchema);
