import 'package:bloc/bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/shared/utils/debouncer.dart';

class _CounterEvent {
  _CounterEvent(this.value);

  final int value;
}

class _DebounceBloc extends Bloc<_CounterEvent, List<int>> {
  _DebounceBloc({Duration duration = const Duration(milliseconds: 50)})
    : super(const []) {
    on<_CounterEvent>(
      (event, emit) => emit([...state, event.value]),
      transformer: debounce(duration),
    );
  }
}

class _AsyncEvent {
  _AsyncEvent(this.value);

  final int value;
}

class _AsyncDebounceBloc extends Bloc<_AsyncEvent, List<int>> {
  _AsyncDebounceBloc()
    : super(const []) {
    on<_AsyncEvent>((event, emit) async {
      await Future.delayed(const Duration(milliseconds: 80));
      emit([...state, event.value]);
    }, transformer: debounce(const Duration(milliseconds: 30)));
  }
}

void main() {
  group('debounce (EventTransformer)', () {
    test(
      'no emite nada mientras no pase la duración de debounce '
      '(bloc_test.close() al final del helper flushea el buffer, así que '
      'este caso se prueba manualmente sin cerrar el bloc)',
      () async {
        final bloc = _DebounceBloc();
        final states = <List<int>>[];
        final subscription = bloc.stream.listen(states.add);

        bloc.add(_CounterEvent(1));
        await Future.delayed(const Duration(milliseconds: 10));

        expect(states, isEmpty);

        await subscription.cancel();
        await bloc.close();
      },
    );

    blocTest<_DebounceBloc, List<int>>(
      'colapsa un burst de eventos rápidos en una sola emisión con el último valor',
      build: () => _DebounceBloc(),
      act: (bloc) {
        bloc.add(_CounterEvent(1));
        bloc.add(_CounterEvent(2));
        bloc.add(_CounterEvent(3));
      },
      wait: const Duration(milliseconds: 120),
      expect: () => [
        [3],
      ],
    );

    blocTest<_DebounceBloc, List<int>>(
      'emite por separado eventos espaciados más que la ventana de debounce',
      build: () => _DebounceBloc(),
      act: (bloc) async {
        bloc.add(_CounterEvent(1));
        await Future.delayed(const Duration(milliseconds: 120));
        bloc.add(_CounterEvent(2));
      },
      wait: const Duration(milliseconds: 120),
      expect: () => [
        [1],
        [1, 2],
      ],
    );

    blocTest<_AsyncDebounceBloc, List<int>>(
      'switchMap cancela la emisión pendiente del evento previo si llega uno nuevo',
      build: () => _AsyncDebounceBloc(),
      act: (bloc) async {
        bloc.add(_AsyncEvent(1));
        // Pasa el debounce (30ms) del primer evento, dejando su handler
        // (80ms) en pleno vuelo, y antes de que termine llega un segundo
        // evento: switchMap debe descartar la emisión del primero.
        await Future.delayed(const Duration(milliseconds: 50));
        bloc.add(_AsyncEvent(2));
      },
      wait: const Duration(milliseconds: 200),
      expect: () => [
        [2],
      ],
    );
  });
}
