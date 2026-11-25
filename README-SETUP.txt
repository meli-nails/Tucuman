MELI NAILS · INTEGRACIÓN CON SUPABASE EXISTENTE
================================================

ARCHIVOS
- index.html: web pública integrada con catálogo, agenda y solicitudes.
- admin.html: panel de administración con Supabase Auth.
- supabase-config.js: URL y clave publishable del proyecto conectado.
- supabase-schema.sql: NO ejecutar en el proyecto actual; es un esquema antiguo de referencia.
- migration-booking-v2.sql: migración aplicada para modalidad y extras.

PROYECTO CONECTADO
- Project ref: vfkalbukfiyprugqepcy
- URL: https://vfkalbukfiyprugqepcy.supabase.co
- Auth: inicio de sesión por email y contraseña; el usuario debe existir en public.admins.
- Catálogo: public.services y public.designs.
- Reservas: public.bookings y public.clients.
- Disponibilidad: RPC get_available_slots.
- Crear solicitud: RPC create_booking_request_v2.

SEGURIDAD
Se incluye únicamente la clave publishable pública. No agregar service_role ni secret keys al frontend.
RLS y la membresía admins siguen siendo la autoridad de acceso.

PUBLICACIÓN
Subí index.html, admin.html y supabase-config.js en la misma carpeta/origen. Abrí admin.html e iniciá sesión con el usuario ya autorizado en public.admins.

NOTAS
- Los diseños de muestra (is_sample=true) no aparecen en el catálogo público hasta que se publiquen desde el panel.
- Al editar/publicar un registro de muestra desde el panel, se marca is_sample=false.
- La reserva requiere servicio; diseño es opcional y suma su extra_price.
- Los importes de servicio, diseño y extras se calculan en PostgreSQL.
- La solicitud se registra antes de abrir WhatsApp; si falla el guardado, no se envía un mensaje que aparente una reserva registrada.
- La disponibilidad se consulta en tiempo real según working_hours, time_blocks, min_notice y reservas existentes.
