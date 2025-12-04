{
Кроссплатформенный модуль для атомарных операций.

Этот модуль содержит типы и функции для выполнения атомарных операций,
необходимых при сборке Python без GIL (Global Interpreter Lock)
(Include\cpython\pyatomic.h).
}

{$mode objfpc}
{$I config.inc}// ключи компиляции

unit py_atomic_ext;


interface

uses
  ctypes, python;

var

  _Py_atomic_load_uint8_relaxed: function(obj: Puint8_t): uint8_t;


procedure init;

implementation

procedure init;
begin
  Pointer(_Py_atomic_load_uint8_relaxed) := GetProc('_Py_atomic_load_uint8_relaxed');
end;


end.
