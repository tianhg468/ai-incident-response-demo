// Simple Express server for demo purposes
const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

// Track metrics
let requestCount = 0;
let errorCount = 0;
let memoryLeak = [];

// Middleware
app.use(express.json());

// Request counter
app.use((req, res, next) => {
  requestCount++;
  next();
});

// Health check
app.get('/', (req, res) => {
  res.json({
    status: 'OK',
    service: 'demo-app',
    version: process.env.APP_VERSION || 'v1',
    uptime: process.uptime(),
    requests: requestCount
  });
});

// Detailed health
app.get('/health', (req, res) => {
  const memUsage = process.memoryUsage();
  res.json({
    status: 'healthy',
    memory: {
      rss: `${Math.round(memUsage.rss / 1024 / 1024)}Mi`,
      heapTotal: `${Math.round(memUsage.heapTotal / 1024 / 1024)}Mi`,
      heapUsed: `${Math.round(memUsage.heapUsed / 1024 / 1024)}Mi`,
      external: `${Math.round(memUsage.external / 1024 / 1024)}Mi`
    },
    uptime: Math.round(process.uptime()),
    requests: requestCount,
    errors: errorCount
  });
});

// Prometheus-style metrics
app.get('/metrics', (req, res) => {
  res.set('Content-Type', 'text/plain');
  res.send(`
# HELP http_requests_total Total HTTP requests
# TYPE http_requests_total counter
http_requests_total ${requestCount}

# HELP http_errors_total Total HTTP errors
# TYPE http_errors_total counter
http_errors_total ${errorCount}

# HELP process_uptime_seconds Process uptime
# TYPE process_uptime_seconds gauge
process_uptime_seconds ${Math.round(process.uptime())}

# HELP process_memory_bytes Process memory usage
# TYPE process_memory_bytes gauge
process_memory_bytes ${process.memoryUsage().rss}
  `.trim());
});

// Trigger OOM (for testing)
app.post('/oom', (req, res) => {
  console.log('⚠️  OOM trigger activated - filling memory...');
  res.json({ status: 'triggering OOM...', message: 'Pod will crash soon' });

  // Fill memory until OOM
  setInterval(() => {
    const chunk = new Array(1024 * 1024).fill('x'); // 1MB chunk
    memoryLeak.push(chunk);
    console.log(`Memory usage: ${Math.round(process.memoryUsage().rss / 1024 / 1024)}Mi`);
  }, 100);
});

// Trigger crash (for testing)
app.post('/crash', (req, res) => {
  console.log('⚠️  Crash trigger activated - exiting...');
  res.json({ status: 'crashing...', message: 'Pod will exit now' });

  setTimeout(() => {
    process.exit(1);
  }, 1000);
});

// Trigger errors (for testing)
app.post('/errors', (req, res) => {
  console.log('⚠️  Error trigger activated - generating 5xx errors...');
  res.json({ status: 'triggering errors...', message: 'Will generate errors on next requests' });

  // Make next 10 requests fail
  let errorMode = 10;
  app.use((req, res, next) => {
    if (errorMode > 0) {
      errorMode--;
      errorCount++;
      return res.status(500).json({ error: 'Internal Server Error (simulated)' });
    }
    next();
  });
});

// Catch-all for 404
app.use((req, res) => {
  res.status(404).json({ error: 'Not Found' });
});

// Error handler
app.use((err, req, res, next) => {
  console.error('Error:', err);
  errorCount++;
  res.status(500).json({ error: 'Internal Server Error' });
});

// Start server
const server = app.listen(port, () => {
  console.log(`✅ Demo app listening on port ${port}`);
  console.log(`📊 Health: http://localhost:${port}/health`);
  console.log(`📈 Metrics: http://localhost:${port}/metrics`);
  console.log(`🔴 Version: ${process.env.APP_VERSION || 'v1'}`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('📥 SIGTERM received, shutting down gracefully...');
  server.close(() => {
    console.log('✅ Server closed');
    process.exit(0);
  });
});
