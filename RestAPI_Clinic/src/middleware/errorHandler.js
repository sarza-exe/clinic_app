// src/middleware/errorHandler.js

//  Catches any errors passed via next(err) and formats the response.
module.exports = (err, req, res, next) => {
    // Log full error for internal debugging
    console.error(err.stack);
  
    // Default status code and message
    const statusCode = err.status || err.statusCode || 500;
    const message = err.message || 'Internal Server Error';
  
    const response = {
      error: message,
    };
  
    // Include validation details if available (e.g., from Mongoose)
    if (err.name === 'ValidationError') {
      res.status(400);
      response.details = Object.values(err.errors).map(e => e.message);
    } else {
      res.status(statusCode);
    }

    // Handle Mongoose cast errors (invalid ObjectId, etc.)
  if (err.name === 'CastError') {
    return res.status(400).json({ error: `Invalid ${err.path}: ${err.value}` });
  }
  
    res.json(response);
  };

  