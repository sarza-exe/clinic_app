// seed.js
require('dotenv').config();
const mongoose  = require('mongoose');
const connectDB = require('./config/db');
const Doctor = require('./models/Doctor');
const Patient = require('./models/patient');
const Appointment = require('./models/Appointment');
const bcrypt = require('bcryptjs');

// --- Seed func ---
async function seed() {
  await connectDB();

  // Clear database
  await Promise.all([
    Doctor.deleteMany({}),
    Patient.deleteMany({}),
    Appointment.deleteMany({})
  ]);

  const head = await Doctor.create({
    name: 'John Doe',
    specialty: 'Cardiology',
    email: 'doe@clinic.com',
    passwordHash: await bcrypt.hash('Secret123', 10),
    role: 'admin'
  });

  const doc = await Doctor.create({
    name: 'Andrew Paradise',
    specialty: 'Cardiology',
    email: 'paradise@clinic.com',
    passwordHash: await bcrypt.hash('Secret321', 10),
  });

  const pat = await Patient.create({
    name: 'Ann Smith',
    birthDate: new Date('1990-05-20'),
    email: 'ann.smith@example.com',
    phone: '+48123123123',
    passwordHash: await bcrypt.hash('Patient1', 10)
  });

  const appointment = await Appointment.create({
    doctor: doc._id,
    patient: pat._id,
    date: new Date(Date.now() + 24 * 60 * 60 * 1000),  //tommorow
    status: 'scheduled',
    reason: 'Follow up on previous visit'
  });

  console.log('✅ Dane przykładowe zostały wstawione:');
  //console.log({ doctor: doc, patient: pat, appointment });
  await mongoose.disconnect();
  process.exit();
}

// Uruchomienie skryptu
seed().catch(err => {
  console.error('❌ Błąd podczas seedowania:', err);
  process.exit(1);
});
