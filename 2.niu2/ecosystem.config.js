module.exports = {
  apps: [
    {
      name: 'newton-lab',
      script: 'preview',
      args: '--port 3001 --host 0.0.0.0',
      cwd: '/var/www/newton-lab',
      instances: 'max',
      exec_mode: 'cluster',
      env: {
        NODE_ENV: 'development'
      },
      env_production: {
        NODE_ENV: 'production',
        DOUBAO_API_KEY: process.env.DOUBAO_API_KEY
      },
      error_file: './logs/err.log',
      out_file: './logs/out.log',
      log_file: './logs/combined.log',
      time: true
    }
  ]
};