require('dotenv').config();
const express = require('express');
const connectDB = require('./config/db');
// router import
const doctorsRouter      = require('./routes/doctors');
const patientsRouter     = require('./routes/patients');
const appointmentsRouter = require('./routes/appointments');

const authRouter = require('./routes/auth');
const authJWT = require('./middleware/authJWT');
const role = require('./middleware/role');

const errorHandler = require('./middleware/errorHandler');

const app = express();
app.use(express.json());

const cors = require('cors');
app.use(cors());

// Auth routes
app.use('/api/auth', authRouter);

app.use('/api/doctors', doctorsRouter);
app.use('/api/patients', authJWT, patientsRouter);
app.use('/api/appointments', authJWT, appointmentsRouter);

app.use(errorHandler);

connectDB().then(() => {
  const PORT = process.env.PORT || 3000;
  app.listen(PORT, () => console.log(`Server run on port ${PORT}`));
});

//tree */