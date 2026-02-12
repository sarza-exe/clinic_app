// src/models/Appointment.js
const mongoose = require('mongoose');

const appointmentSchema = new mongoose.Schema({
  doctor:   { type: mongoose.Schema.Types.ObjectId, ref: 'Doctor',  required: true },
  patient:  { type: mongoose.Schema.Types.ObjectId, ref: 'Patient', required: true },
  date:     { type: Date, required: true },
  status:   { type: String, enum: ['awaiting approval','scheduled','done','cancelled'], default: 'scheduled' },
  reason:   { type: String, required: true }
}, { timestamps: true });

module.exports = mongoose.model('Appointment', appointmentSchema);
