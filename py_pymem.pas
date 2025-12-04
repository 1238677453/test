{$mode objfpc}
{$I config.inc}
unit py_pymem;

interface

uses
  ctypes, python;



{ ==================================================================
  Низкоуровневый интерфейс выделения памяти PyMem_*/PyMem_Raw*.
  Адаптация CPython Include/pymem.h (ветка main, CPython 3.14) для FPC.

  Публичный API оформлен как процедурные переменные (var) для динамической
  привязки через GetProc (см. py_common). Макросы PyMem_New/PyMem_Resize и
  их алиасы представлены как inline-функции/процедуры Pascal.

  ВАЖНО (по мотивам комментария в pymem.h):
  - Не смешивайте PyMem_* с прямыми вызовами malloc/realloc/calloc/free.
    Например, на Windows разные DLL могут использовать разные кучи, и блок,
    выделенный PyMem_Malloc, нельзя освобождать через free().
  - В сборках с Py_DEBUG CPython может оборачивать все PyMem_*/PyObject_*
    в отладочные обёртки, добавляющие служебную информацию к блокам памяти.
    Системные функции распределения памяти не знают об этих метаданных и не
    должны использоваться для таких блоков.
  - Для функций PyMem_* (кроме PyMem_Raw*) требуется удерживать GIL.

  Комментарии на русском языке адаптированы по документации CPython
  и исходникам pymem.h/cpython/pymem.h.
  ================================================================== }

  { ------------------------------------------------------------------ }
  { Функции семейства PyMem_ (требуют удержания GIL) }
  { ------------------------------------------------------------------ }

var
  { PyMem_Malloc(size) -> Pointer
    Выделяет size байт памяти с семантикой, совместимой с malloc(), но с
    гарантией, что запрос 0 байт по возможности вернёт ненулевой указатель.
    При неудаче возвращает nil, исключения не устанавливаются. }
  PyMem_Malloc: function(size: csize_t): Pointer; cdecl;

  { PyMem_Calloc(nelem, elsize) -> Pointer
    Выделяет nelem элементов по elsize байт каждый и обнуляет память.
    При неудаче возвращает nil, исключения не устанавливаются. }
  PyMem_Calloc: function(nelem, elsize: csize_t): Pointer; cdecl;

  { PyMem_Realloc(ptr, new_size) -> Pointer
    Реализует семантику realloc() для блока, ранее выделенного PyMem_*.
    При неудаче возвращает nil, исходный блок остаётся валиден. }
  PyMem_Realloc: function(ptr: Pointer; new_size: csize_t): Pointer; cdecl;

  { PyMem_Free(ptr)
    Освобождает память, ранее выделенную PyMem_*. Аналог free(), но должен
    использоваться только вместе с PyMem_ семейством. }
  PyMem_Free: procedure(ptr: Pointer); cdecl;

{$IFNDEF PY_LIMITED_API}
  { ------------------------------------------------------------------ }
  { Функции семейства PyMem_Raw* (не требуют GIL) }
  { ------------------------------------------------------------------ }

  { PyMem_RawMalloc(size) -> Pointer
    Выделяет size байт памяти без требования удерживать GIL (обычно thin-wrapper
    над malloc()). tracemalloc может отслеживать такие выделения. }
  PyMem_RawMalloc: function(size: csize_t): Pointer; cdecl;

  { PyMem_RawCalloc(nelem, elsize) -> Pointer
    Аналог calloc() без требования удерживать GIL. }
  PyMem_RawCalloc: function(nelem, elsize: csize_t): Pointer; cdecl;

  { PyMem_RawRealloc(ptr, new_size) -> Pointer
    Аналог realloc() без требования удерживать GIL. }
  PyMem_RawRealloc: function(ptr: Pointer; new_size: csize_t): Pointer; cdecl;

  { PyMem_RawFree(ptr)
    Аналог free() для блоков, выделенных PyMem_Raw*. }
  PyMem_RawFree: procedure(ptr: Pointer); cdecl;
{$ENDIF}

  { ------------------------------------------------------------------ }
  { Inline-реализации макросов PyMem_New / PyMem_Resize и алиасов }
  { ------------------------------------------------------------------ }

{ PyMem_New(type, n): безопасное выделение массива из n элементов заданного типа.
  При переполнении sizeof(type) * n возвращает nil. }
function PyMem_New(elt_size: csize_t; n: Py_ssize_t): Pointer; inline;

{ PyMem_Resize(p, type, n): безопасное переразмеривание массива p.
  При переполнении или ошибке возвращает nil, при этом p считается
  перезаписанным — вызывающий код должен сохранить старое значение. }
function PyMem_Resize(p: Pointer; elt_size: csize_t; n: Py_ssize_t): Pointer; inline;

implementation

function PyMem_New(elt_size: csize_t; n: Py_ssize_t): Pointer; inline;
begin
  if (n < 0) or (csize_t(n) > High(Py_ssize_t) div elt_size) then
    Exit(nil);
  Result := PyMem_Malloc(csize_t(n) * elt_size);
end;

function PyMem_Resize(p: Pointer; elt_size: csize_t; n: Py_ssize_t): Pointer; inline;
begin
  if (n < 0) or (csize_t(n) > High(Py_ssize_t) div elt_size) then
    Exit(nil);
  Result := PyMem_Realloc(p, csize_t(n) * elt_size);
end;

initialization
  { Привязка функций PyMem_* через GetProc (объявлена в py_common). }
  Pointer(PyMem_Malloc)  := GetProc('PyMem_Malloc');
  Pointer(PyMem_Calloc)  := GetProc('PyMem_Calloc');
  Pointer(PyMem_Realloc) := GetProc('PyMem_Realloc');
  Pointer(PyMem_Free)    := GetProc('PyMem_Free');

  {$IFNDEF PY_LIMITED_API}
  Pointer(PyMem_RawMalloc) := GetProc('PyMem_RawMalloc');
  Pointer(PyMem_RawCalloc) := GetProc('PyMem_RawCalloc');
  Pointer(PyMem_RawRealloc) := GetProc('PyMem_RawRealloc');
  Pointer(PyMem_RawFree) := GetProc('PyMem_RawFree');
  {$ENDIF}

finalization
end.
