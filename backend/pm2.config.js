module.exports = {
  apps: [{
    name: 'ghumakkad-api',
    script: './ghumakkad_server',
    args: '',
    cwd: '/var/www/ghumakkad/backend',
    instances: 1,
    autorestart: true,
    watch: false,
    max_memory_restart: '300M',
    env: {
      NODE_ENV: 'production',
      DART_ENV: 'production'
    },
    error_file: '/var/log/ghumakkad/error.log',
    out_file: '/var/log/ghumakkad/out.log',
    log_date_format: 'YYYY-MM-DD HH:mm:ss'
  }]
}
