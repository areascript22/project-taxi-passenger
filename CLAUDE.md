# CLAUDE.md — Plantilla compartida (Driver App / Passenger App)

Este archivo define las reglas de arquitectura y estilo de código que Claude
Code debe seguir **siempre** al trabajar en este proyecto.

> 📌 **Nota:** Driver App y Passenger App son **dos proyectos Flutter
> separados** (repos distintos), pero comparten exactamente la misma
> arquitectura y convenciones. Este archivo `CLAUDE.md` debe copiarse tal
> cual en la raíz de **cada uno** de los dos proyectos.
>
> Los ejemplos de código usan nombres **genéricos** (`app`, `Profile`, etc.)
> a propósito, para que no se confundan con features específicos de una sola
> app. Al aplicarlos, usa el `package name` real del proyecto en el que estés
> trabajando (revisa el `pubspec.yaml` / los imports existentes del proyecto).

---

## 1. Arquitectura del proyecto

El proyecto se organiza en tres capas principales:

```
lib/
 ├─ core/        # Código transversal a toda la app (network, error, utils, theme, etc.)
 ├─ shared/      # Widgets, entidades o lógica reutilizable entre features
 └─ features/
     └─ <feature_name>/
         ├─ presentation/   # UI: pages, widgets, bloc/cubit
         ├─ domain/         # Entities, repository interfaces (contracts)
         ├─ data/            # Implementación de repositorios/servicios + models
         └─ di/              # Registro de dependencias propias del feature
```

**Flujo de datos del proyecto:**

```
UI  →  Bloc / Cubit  →  Repositorio o Servicio (o una orquestación de ambos)
```

- **No usamos capa de `datasource`.** El repositorio (o servicio) se
  comunica directamente con la fuente de datos (API, SDK, storage local,
  etc.) sin una capa intermedia adicional.
- Un Bloc/Cubit puede depender de un repositorio, de un servicio, o de
  ambos si la lógica requiere orquestar más de una fuente.
- La UI nunca llama directamente a un repositorio o servicio: siempre pasa
  por el Bloc/Cubit correspondiente.

**Reglas generales:**
- Cada feature es autocontenida: no debe importar directamente código `data`
  o `presentation` de otro feature. Si necesita compartir algo, ese algo va en
  `shared/` o `core/`.
- El `di/` de cada feature registra **únicamente** lo que pertenece a ese
  feature: repositorios, servicios, utils y Blocs/Cubits propios.
- Cada feature debe tener su propia función de inicialización, por ejemplo
  `initAuthDI(GetIt sl)`, `initRequestDI(GetIt sl)`, etc., y esta función se
  registra luego en el `service_locator` global de la app.

Ejemplo de referencia (`auth_service_locator.dart`):

```dart
import 'package:get_it/get_it.dart';
import 'package:app/features/auth/data/repository/auth_repository_impl.dart';
import 'package:app/features/auth/domain/repository/auth_repository.dart';
import 'package:app/features/auth/presentation/bloc/auth_bloc.dart';

void initAuthDI(GetIt sl) {
  sl.registerFactory<AuthRepository>(() => AuthRepositoryImpl());
  sl.registerFactory(() => AuthBloc(authRepository: sl<AuthRepository>()));
}
```

> El `import 'package:app/...'` es un placeholder: reemplázalo por el
> package name real de Driver App o Passenger App según en cuál estés
> trabajando (nunca mezclar imports de un proyecto dentro del otro).

Este patrón (`register... -> Implementación concreta -> Interfaz`) debe
replicarse en todos los features nuevos, respetando `registerFactory`,
`registerLazySingleton` o `registerSingleton` según corresponda al ciclo de
vida esperado del objeto.

---

## 2. Diálogos y PopUps

Todo diálogo o popup del proyecto debe seguir este patrón:

- Debe ser un `StatelessWidget` (o `StatefulWidget` si requiere estado
  interno).
- Debe exponer un método **estático** llamado `show` que internamente llame a
  `showDialog`, `showModalBottomSheet`, etc.
- **Nunca** se debe invocar `showDialog(...)` directamente fuera del widget;
  siempre se usa `NombreDelDialogo.show(...)`.

```dart
class ConfirmDialog extends StatelessWidget {
  const ConfirmDialog({super.key, required this.message});

  final String message;

  static Future<bool?> show(
    BuildContext context, {
    required String message,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ConfirmDialog(message: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Aceptar'),
        ),
      ],
    );
  }
}
```

Uso esperado: `await ConfirmDialog.show(context, message: '¿Seguro?');`

---

## 3. Manejo de errores con Dartz (Either)

El proyecto usa `dartz: ^0.10.1` para manejo de errores. **Todo** método de
un **servicio** o **repositorio** debe devolver `Future<Either<Failure, T>>`,
donde `T` es el tipo de dato exitoso esperado.

- El lado izquierdo (`Left`) siempre es un `Failure`.
- El lado derecho (`Right`) siempre es el resultado exitoso.
- Nunca se debe lanzar (`throw`) una excepción hacia arriba desde un
  repositorio o servicio; toda excepción se captura y se transforma en un
  `Failure`.

```dart
Future<Either<Failure, ProfileEntity>> fetchProfile({required String userId});
```

Esta regla aplica tanto a las interfaces del `domain` (contratos) como a sus
implementaciones concretas en `data`.

> Nota: `fetchProfile` es solo un ejemplo genérico (aplica igual en Driver
> App y en Passenger App, ya que ambas manejan perfil de usuario). Los
> métodos reales de cada proyecto reflejarán sus propios features
> (ej. en Passenger App: `requestTrip`; en Driver App: `acceptTrip`), pero
> siempre siguiendo esta misma firma con `Either<Failure, Entity>`.

---

## 4. Model vs Entity

> ⚠️ Esta distinción todavía se está afinando en el proyecto. Por ahora se
> sigue la siguiente convención mínima; puede evolucionar más adelante.

- **Model** (vive en `data/models/`): representa la data tal como llega/sale
  de la fuente externa (API, storage, etc.).
  - Contiene los métodos `fromJson`, `toJson` (y similares) para
    serialización/deserialización.
  - Contiene un método `toEntity()` que convierte el Model en su Entity
    correspondiente.
- **Entity** (vive en `domain/entities/`): representa el objeto de negocio
  puro que usa el resto de la app (Bloc/Cubit, UI).
  - Contiene **únicamente los campos**, sin lógica de serialización ni
    dependencias de la fuente de datos.
- **Por cada Model debe existir su Entity correspondiente.** El repositorio o
  servicio es responsable de recibir el Model y devolver siempre la Entity
  hacia arriba (nunca se debe exponer un Model fuera de la capa `data`).

```dart
// data/models/profile_model.dart
class ProfileModel {
  ProfileModel({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
  });

  final String id;
  final String fullName;
  final String phoneNumber;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      fullName: json['full_name'],
      phoneNumber: json['phone_number'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone_number': phoneNumber,
    };
  }

  ProfileEntity toEntity() {
    return ProfileEntity(
      id: id,
      fullName: fullName,
      phoneNumber: phoneNumber,
    );
  }
}
```

```dart
// domain/entities/profile_entity.dart
class ProfileEntity {
  ProfileEntity({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
  });

  final String id;
  final String fullName;
  final String phoneNumber;
}
```

---

## 5. Parámetros siempre nombrados

Todos los métodos que reciben parámetros —sean opcionales o requeridos— deben
declararlos como **parámetros nombrados**, nunca posicionales. Esto obliga a
que cada llamada especifique explícitamente el nombre del parámetro.

✅ Correcto:

```dart
Future<Either<Failure, ProfileEntity>> fetchProfile({required String userId});

Future<Either<Failure, void>> updateProfile({
  required String userId,
  String? phoneNumber,
});
```

❌ Incorrecto (parámetros posicionales):

```dart
Future<Either<Failure, ProfileEntity>> fetchProfile(String userId);
```

Esta regla aplica a **todos** los métodos del proyecto (repositorios,
servicios, use cases, funciones de widgets, etc.), no solo a los que
devuelven `Either`.

---

## 6. Try/Catch obligatorio con debugPrint contextual

Todo método de un **servicio** o **repositorio** debe envolver su lógica en
un bloque `try/catch`:

- En el `catch`, siempre se debe imprimir el error con `debugPrint`
  (`import 'package:flutter/material.dart';`).
- El mensaje de `debugPrint` debe llevar un **prefijo/sufijo por contexto**,
  que identifique el feature o repositorio de origen dentro del proyecto
  actual. Ejemplos de prefijo:
  - Repositorio de perfil → `"ProfileDebug | ..."`
  - Repositorio de autenticación → `"AuthDebug | ..."`
  - Repositorio de viajes → `"TripDebug | ..."`
- En caso de error, el método debe devolver `Left(Failure(...))` con un
  mensaje descriptivo; nunca debe dejar la excepción sin capturar.

Recuerda: como no usamos `datasource`, el repositorio/servicio llama
directamente al cliente HTTP, SDK o storage, mapea el resultado (Model →
Entity con `toEntity()`) y retorna la Entity dentro de `Right(...)`.

```dart
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl({required this.apiClient});

  final ApiClient apiClient;

  @override
  Future<Either<Failure, ProfileEntity>> fetchProfile({
    required String userId,
  }) async {
    try {
      final response = await apiClient.get('/profile/$userId');
      final model = ProfileModel.fromJson(response.data);
      return Right(model.toEntity());
    } catch (e) {
      debugPrint('ProfileDebug | Error en fetchProfile: $e');
      return Left(Failure(message: 'No se pudo obtener el perfil'));
    }
  }
}
```

**Convención de prefijos por feature.** Cada proyecto (Driver App y
Passenger App) mantiene **su propia tabla**, con los features que existan en
ese proyecto en particular — no se mezclan features de un proyecto dentro
del otro. Ejemplo de tabla para un proyecto:

| Feature / Repositorio | Prefijo de debugPrint |
|------------------------|------------------------|
| Auth                    | `AuthDebug \|`         |
| Profile                 | `ProfileDebug \|`      |
| Trip                    | `TripDebug \|`         |
| Payments                | `PaymentsDebug \|`     |
| Notifications           | `NotificationsDebug \|`|

Cuando se cree un feature nuevo sin prefijo definido en esta tabla, se debe
crear uno consistente con el nombre del feature (ej. `Chat` → `ChatDebug |`)
y añadirlo a esta tabla **dentro del proyecto correspondiente**.

---

## 7. Checklist rápido al crear un repositorio o servicio nuevo

Antes de dar por terminado un repositorio o servicio, verificar que:

- [ ] El método está en la capa correcta (`domain` = contrato, `data` = implementación).
- [ ] Devuelve `Future<Either<Failure, T>>`, donde `T` es una **Entity** (nunca un Model).
- [ ] Si el resultado viene de un JSON, existe un Model con `fromJson`/`toJson`/`toEntity()`
      y su Entity correspondiente con solo los campos.
- [ ] Todos los parámetros son nombrados (`{required ...}` / `{...}`).
- [ ] No hay capa `datasource`: el repositorio/servicio llama directamente a la fuente.
- [ ] La lógica está envuelta en `try/catch`.
- [ ] El `catch` usa `debugPrint` con el prefijo de contexto correcto.
- [ ] El `catch` retorna `Left(Failure(...))`, nunca relanza la excepción.
- [ ] Si el repositorio/servicio es nuevo, está registrado en su `di/` correspondiente.

---

## 8. Estructura de un feature nuevo (resumen)

```
features/<feature_name>/
 ├─ presentation/
 │   ├─ bloc/ (o cubit/)
 │   ├─ pages/
 │   └─ widgets/       # Incluye Dialogs con patrón .show()
 ├─ domain/
 │   ├─ entities/       # Solo campos, sin lógica de serialización
 │   └─ repository/     # Contratos (interfaces) con Either<Failure, Entity>
 ├─ data/
 │   ├─ models/          # fromJson / toJson / toEntity()
 │   └─ repository/     # Implementación: try/catch + debugPrint, llama a la fuente directo
 └─ di/
     └─ <feature_name>_service_locator.dart
```
