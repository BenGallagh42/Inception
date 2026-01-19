# User Documentation

## Services provided

- **NGINX** - HTTPS web server on port 443
- **WordPress** - Website with PHP-FPM
- **MariaDB** - Database

## Start and stop

**Start:**
```bash
make
```

**Stop:**
```bash
make down
```

## Access

**Website:**
```
https://bboulmie.42.fr
```

**Admin panel:**
```
https://bboulmie.42.fr/wp-admin
```

## Credentials

Location: `secrets/` folder

- `db_password.txt` - Database password
- `db_root_password.txt` - Root password  
- `credentials.txt` - WordPress users

**Users:**
- Admin: `inception` (password in credentials.txt)
- User: `regular_user` (password in credentials.txt)

## Check services
```bash
make ps
```

All containers should show "Up".

**View logs:**
```bash
make logs
```