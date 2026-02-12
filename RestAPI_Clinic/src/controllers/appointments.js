// src/controllers/appointments.js
const Appointment = require('../models/appointment');
const Doctor = require('../models/doctor');
const Patient = require('../models/patient');

exports.getAppointments = async (req, res) => {
  try {
    const { page = 1, limit = 10, doctor, patient, date, sort = 'asc' } = req.query;

    const filters = {};

    const uid = req.user.id;
    const role = req.user.role;
    if (role !== 'admin' && role !== 'doctor') {
      filters.patient = uid;
    }
    else{
	// Resolve doctor name to ID if provided
      if (doctor) {
        const doctorDoc = await Doctor.findOne({ name: doctor }); // Assumes 'name' field exists
        if (!doctorDoc) {
          return res.status(404).json({ message: `Doctor '${doctor}' not found.` });
        }
        filters.doctor = doctorDoc._id;
      }

      // Resolve patient name to ID if provided
      if (patient) {
        const patientDoc = await Patient.findOne({ name: patient }); // Assumes 'name' field exists
        if (!patientDoc) {
          return res.status(404).json({ message: `Patient '${patient}' not found.` });
        }
        filters.patient = patientDoc._id;
      }
    }

    if (date) filters.date = { $gte: new Date(date) };

    const sortOrder = req.query.sort === 'asc' ? 1 : -1;

    const appointments = await Appointment.find(filters)
      .sort({ date: sortOrder })
      .skip((page - 1) * limit)
      .limit(Number(limit))
      .populate('doctor', 'name')
      .populate('patient', 'name');

    res.json(appointments);
  } catch (err) {
    res.status(500).json({ message: 'Server error', error: err.message });
  }
};

// GET /appointments?page=&limit=&doctor=&patient=&date
// GET /appointments?page=&limit=&doctor=&patient=&date&sort
exports.getAll = async (req, res, next) => {
  try {
    const { role, id: uid } = req.user;

    const page  = parseInt(req.query.page, 10)  || 1;
    const limit = parseInt(req.query.limit, 10) || 20;
    const skip  = (page - 1) * limit;

    // Build filter
    const filter = {};
    if (role === 'doctor' || role === 'admin') {
// for doctor/admin, allow optional ?patient= or ?doctor= …
      if (req.query.patient) filter.patient = req.query.patient;
      if (req.query.doctor)  filter.doctor  = req.query.doctor;
      if (req.query.date)    filter.date    = { $gte: new Date(req.query.date) };
    } else {
      // force-filter by self
      filter.patient = uid;
    }

    // Determine sort order: 'asc' or 'desc'
    const sortOrder = req.query.sort === 'desc' ? -1 : 1;

    const [total, appointments] = await Promise.all([
      Appointment.countDocuments(filter),
      Appointment.find(filter)
        .populate('doctor', 'name specialty')
        .populate('patient', 'name email')
        .sort({ date: sortOrder })
        .skip(skip)
        .limit(limit)
    ]);

    res.json({ page, limit, total, data: appointments });
  } catch (err) {
    next(err);
  }
};

// GET /appointments/:id
exports.getById = async (req, res, next) => {
  try {
    const appt = await Appointment.findById(req.params.id)
      .populate('doctor', 'name specialty email')
      .populate('patient', 'name email');
    if (!appt) return res.status(404).json({ error: 'Appointment not found' });

    const uid = req.user.id;
    const role = req.user.role;
    if (role !== 'admin' && role !== 'doctor' && uid !== appt.patient.id) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    res.json(appt);
  } catch (err) {
    next(err);
  }
};

// POST /appointments
exports.create = async (req, res, next) => {
  try {
    const { doctor, patient, date, reason } = req.body;
    const uid = req.user.id;
    const role = req.user.role;
    if (role !== 'admin' && role !== 'doctor' && uid !== patient) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    const status = (role === 'patient') ? 'awaiting approval' : 'scheduled';
    const appt = await Appointment.create({ doctor, patient, date, status, reason });
    res.status(201).json(appt);
  } catch (err) {
    next(err);
  }
};

// PUT /appointments/:id
exports.update = async (req, res, next) => {
  try {
    const uid = req.user.id;
    const role = req.user.role;
    const targetId = req.params.id;

    // Find the appointment first
    const appt = await Appointment.findById(targetId);
    if (!appt) return res.status(404).json({ error: 'Appointment not found' });

    // Only the referring doctor or admin can update
    if (role !== 'admin' && uid !== appt.doctor.toString()) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    const updates = { ...req.body };
    // Prevent patients from changing status if that was a concern
    if (role === 'patient') delete updates.status;

    const updatedAppt = await Appointment.findByIdAndUpdate(
      targetId,
      updates,
      { new: true, runValidators: true }
    );
    res.json(updatedAppt);
  } catch (err) {
    next(err);
  }
};
// DELETE /appointments/:id
exports.remove = async (req, res, next) => {
  try {
    const appt = await Appointment.findById(req.params.id);
    if (!appt) return res.status(404).json({ error: 'Appointment not found' });

    const uid = req.user.id;
    const role = req.user.role;
    // allow delete by doctor or the patient
    if (role !== 'admin' && uid !== appt.doctor.toString() && uid !== appt.patient.toString()) {
      return res.status(403).json({ error: 'Forbidden' });
    }

    await Appointment.findByIdAndDelete(req.params.id);
    res.status(204).end();
  } catch (err) {
    next(err);
  }
};