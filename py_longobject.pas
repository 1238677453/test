{
Полная вычитка и адаптация CPython Include/cpython/longobject.h (ветка main, CPython 3.14) для Free Pascal (trunk).
  Этот файл — максимально близкая к upstream версия заголовка longobject.h, адаптированная
  под FPC: публичный API оформлен как процедурные переменные (var) для динамической привязки
  через GetProc. Устаревшие элементы удалены или помечены; внутренние
  символы доступны только при {$IFNDEF PY_LIMITED_API}.

  Комментарии ко всем функциям/типам/макросам на русском языке взяты и адаптированы
  из официальной документации CPython (docs.python.org) и исходников longobject.h.
)
}
{$mode objfpc}
{$I config.inc}
unit py_longobject;

interface

uses
  ctypes,
  python; { предполагается: PPyObject, PPyTypeObject, Py_ssize_t, GetProc }


{ ==================================================================
  Пояснение и соглашения
  ==================================================================
  - Этот модуль не выполняет сложной логики проверки наличия символов:
    GetProc возвращает Pointer или nil; привязки выполняются в initialization.
  - Макросы, реализованные как inline-функции, НЕ привязываются через GetProc.
  - Комментарии содержат подробную информацию о поведении, ошибках и
    правилах владения (newref/borrowed), соответствующую документации CPython.
}

  { ------------------------------------------------------------------ }
  { Константы для Native Bytes API }
  { ------------------------------------------------------------------ }
const
  { Флаги для PyLong_AsNativeBytes / PyLong_FromNativeBytes. }
  Py_ASNATIVEBYTES_DEFAULTS      = -1;           { поведение по умолчанию }
  Py_ASNATIVEBYTES_BIG_ENDIAN    = 0;          { big-endian }
  Py_ASNATIVEBYTES_LITTLE_ENDIAN = 1;       { little-endian }
  Py_ASNATIVEBYTES_NATIVE_ENDIAN = 3;       { порядок байт платформы }
  Py_ASNATIVEBYTES_UNSIGNED_BUFFER = 4;
  { трактовать входной буфер как unsigned }
  Py_ASNATIVEBYTES_REJECT_NEGATIVE = 8;
  { отвергать отрицательные значения при чтении }
  Py_ASNATIVEBYTES_ALLOW_INDEX   = 16;
  { разрешить __index__() для непонятных объектов }

  { ------------------------------------------------------------------ }
  { Типы }
  { ------------------------------------------------------------------ }

type
  { PyLongObject — частичное представление структуры int в CPython.
    Примечание: по Limited API эта структура opaque — нельзя полагаться на внутреннее представление.
    Здесь указаны только поля PyObject_HEAD: ob_refcnt, ob_type, ob_size. }
  PyLongObject = record
    ob_refcnt: Py_ssize_t;      { счётчик ссылок }
    ob_type:   PPyTypeObject;   { указатель на тип }
    ob_size:   Py_ssize_t;
    { количество digit'ов (знак encoded in sign of ob_size) }
  end;
  PPyLongObject = ^PyLongObject;

  { ------------------------------------------------------------------ }
{ Переменные / процедурные указатели (публичный API)
  Порядок объявлений здесь совпадает с порядком привязки в секции initialization. }
  { ------------------------------------------------------------------ }
var
  { PyLong_Type
    Тип объекта int (PyLong). Часть стабильного ABI. }
  PyLong_Type: PPyTypeObject;

  { ----------------- Создание / From* ----------------- }
  { Если не оговорено иначе, функции создания возвращают new reference на PyLong-объект
    или nil при ошибке с установленным исключением (обычно MemoryError, OverflowError
    или TypeError/ValueError для функций парсинга). }

  { PyLong_FromLong(v) -> new PyLong
    Создаёт Python int из значения C long v.
    Возвращает new reference или nil при ошибке (например, MemoryError). }
  PyLong_FromLong: function(v: clong): PPyObject; cdecl;

  { PyLong_FromUnsignedLong(v) -> new PyLong из unsigned long
    Создаёт неотрицательный Python int из значения C unsigned long v.
    При ошибке (как правило, MemoryError) возвращает nil. }
  PyLong_FromUnsignedLong: function(v: culong): PPyObject; cdecl;

  { PyLong_FromSize_t(v) -> new PyLong из size_t
    Создаёт Python int из значения C size_t v. Возвращает new reference или nil
    при ошибке (например, MemoryError). }
  PyLong_FromSize_t: function(v: csize_t): PPyObject; cdecl;

  { PyLong_FromSsize_t(v) -> new PyLong из Py_ssize_t
    Создаёт Python int из значения Py_ssize_t v. Возвращает new reference или nil
    при ошибке. }
  PyLong_FromSsize_t: function(v: Py_ssize_t): PPyObject; cdecl;

  { PyLong_FromDouble(v) -> new PyLong
    Конвертирует C double v в Python int, отбрасывая дробную часть (trunc towards 0).
    Может возбуждать OverflowError, если значение по модулю слишком велико, и возвращать nil. }
  PyLong_FromDouble: function(v: cdouble): PPyObject; cdecl;

  { PyLong_FromLongLong(v) -> new PyLong
    Создаёт Python int из значения C long long v.
    Возвращает new reference или nil при ошибке (обычно MemoryError). }
  PyLong_FromLongLong: function(v: int64): PPyObject; cdecl;

  { PyLong_FromNativeBytes(buffer, n_bytes, flags) -> new PyLong
    Создаёт PyLong из n_bytes байтов по адресу buffer, интерпретируя их согласно флагам
    Py_ASNATIVEBYTES_* (порядок байт, знаковость и т.д.). При n_bytes = 0 всегда
    возвращает 0. При ошибке (например, несовместимые флаги) возвращает nil с
    установленным исключением. }
  PyLong_FromNativeBytes: function(buffer: Pointer; n_bytes: csize_t;
  flags: cint): PPyObject; cdecl;

  { PyLong_FromUnsignedNativeBytes(buffer, n_bytes, flags) -> new PyLong
    Как PyLong_FromNativeBytes, но входной буфер трактуется как беззнаковый при вычислении
    значения, результат всегда неотрицателен. При ошибке возвращает nil и устанавливает
    соответствующее исключение. }
  PyLong_FromUnsignedNativeBytes: function(buffer: Pointer; n_bytes: csize_t;
  flags: cint): PPyObject; cdecl;

  { PyLong_FromString(str, endptr, base) -> new PyLong
    Парсит C-строку str как целое число в основании base (0 — автоопределение, как в C:
    префиксы 0x, 0o, 0b и т.п.). Если endptr <> nil, по этому адресу записывается
    указатель на первый непрочитанный символ.
    Возвращает new reference или nil при ошибке (например, ValueError при некорректном
    формате или TypeError при неверных аргументах). }
  PyLong_FromString: function(str: pansichar; endptr: PPAnsiChar; base: cint): PPyObject; cdecl;

  { PyLong_FromUnicodeObject(u, base) -> new PyLong
    Как PyLong_FromString, но принимает Unicode-объект (строку) u и парсит её как целое.
    base — основание (0 — автоопределение с учётом префиксов). При ошибке (например,
    некорректный формат) возвращает nil и устанавливает исключение, обычно ValueError. }
  PyLong_FromUnicodeObject: function(u: PPyObject; base: cint): PPyObject; cdecl;

  { PyLong_FromVoidPtr(p) -> new PyLong
    Создаёт PyLong, представляющий целочисленное значение указателя p (void*).
    Полезно для сериализации и межъязыкового взаимодействия. Возвращает new reference
    или nil при ошибке. }
  PyLong_FromVoidPtr: function(p: Pointer): PPyObject; cdecl;

  { PyLong_AsVoidPtr(obj) -> void*
    Интерпретирует Python int как целочисленное значение указателя и возвращает его как Pointer.
    При ошибке (неподходящий тип, переполнение и т.п.) возвращает nil и устанавливает исключение. }
  PyLong_AsVoidPtr: function(obj: PPyObject): Pointer; cdecl;

  { PyLong_FromInt32/FromUInt32/FromInt64/FromUInt64
    Создают Python int из точных 32/64-битных C-типов (int32_t/uint32_t/int64_t/uint64_t).
    Эти функции добавлены в стабильный ABI начиная с Python 3.13/3.14.
    Все возвращают new reference или nil при ошибке (обычно MemoryError). }
  PyLong_FromInt32: function(Value: cint32): PPyObject; cdecl;
  PyLong_FromUInt32: function(Value: cuint32): PPyObject; cdecl;
  PyLong_FromInt64: function(Value: cint64): PPyObject; cdecl;
  PyLong_FromUInt64: function(Value: cuint64): PPyObject; cdecl;

  { ----------------- Преобразования / As* (PyLong -> C) ----------------- }

  { PyLong_AsLong(obj) -> C long
    Преобразует obj в C long. Если obj не является int, пытается вызвать __index__() (и
    в старых версиях мог вызывать __int__()).
    При переполнении возбуждает OverflowError и возвращает -1. Так как -1 может быть
    корректным результатом, всегда проверяйте PyErr_Occurred() для различения ошибки
    и валидного значения. }
  PyLong_AsLong: function(obj: PPyObject): clong; cdecl;

  { PyLong_AsLongAndOverflow(obj, &overflow) -> C long
    Как PyLong_AsLong, но дополнительно записывает в *overflow информацию о переполнении:
      *overflow = 0  — переполнения не было;
      *overflow > 0  — положительное переполнение;
      *overflow < 0  — отрицательное переполнение.
    Позволяет отличить переполнение от других ошибок и от корректного результата -1. }
  PyLong_AsLongAndOverflow: function(obj: PPyObject; overflow: Pcint): clong; cdecl;

  { PyLong_AsSsize_t(obj) -> Py_ssize_t
    Преобразует obj в Py_ssize_t. При выходе значения за диапазон Py_ssize_t возбуждает
    OverflowError и возвращает -1. Значение -1 также может быть корректным результатом,
    поэтому при необходимости проверяйте PyErr_Occurred(). }
  PyLong_AsSsize_t: function(obj: PPyObject): Py_ssize_t; cdecl;

  { PyLong_AsSize_t(obj) -> size_t
    Преобразует obj в size_t. При выходе значения за диапазон size_t возбуждает OverflowError
    и возвращает (size_t)-1 (в Pascal: максимальное значение типа). Для обнаружения ошибки
    следует дополнительно проверять PyErr_Occurred(). }
  PyLong_AsSize_t: function(obj: PPyObject): csize_t; cdecl;

  { PyLong_AsUnsignedLong(obj) -> unsigned long
    Преобразует obj в unsigned long. Отрицательные значения и значения вне диапазона
    порождают OverflowError; в этом случае возвращается (unsigned long)-1. Проверяйте
    PyErr_Occurred() для различения ошибки и корректного результата с этим же значением. }
  PyLong_AsUnsignedLong: function(obj: PPyObject): culong; cdecl;

  { PyLong_AsUnsignedLongMask(obj) -> unsigned long (mask)
    Возвращает значение obj по модулю 2**(sizeof(unsigned long)*8), игнорируя переполнение.
    Отрицательные значения приводятся так же, как при приведении к unsigned long в C.
    Ошибки переполнения не генерируются. }
  PyLong_AsUnsignedLongMask: function(obj: PPyObject): culong; cdecl;

  { PyLong_AsLongLong / PyLong_AsLongLongAndOverflow }
  PyLong_AsLongLong: function(obj: PPyObject): int64; cdecl;
  PyLong_AsLongLongAndOverflow: function(obj: PPyObject; overflow: Pcint): int64; cdecl;

  { PyLong_AsUnsignedLongLong(obj) -> unsigned long long
    Преобразует obj в unsigned long long. Выход за диапазон, а также отрицательные значения
    приводят к возбуждению OverflowError и возврату (unsigned long long)-1. Для различения
    ошибки и валидного результата следует проверять PyErr_Occurred(). }
  PyLong_AsUnsignedLongLong: function(obj: PPyObject): QWord; cdecl;

  { PyLong_AsUnsignedLongLongMask(obj) -> uint64 (mask conversion)
    Возвращает значение по модулю 2**64 без генерации OverflowError. Отрицательные значения
    обрабатываются как при приведении к unsigned long long в C. }
  PyLong_AsUnsignedLongLongMask: function(obj: PPyObject): QWord; cdecl;

  { PyLong_AsDouble(obj) -> double
    Конвертирует Python int в C double. Для очень больших значений может произойти потеря
    точности или Floating-point overflow (в этом случае генерируется OverflowError и
    возвращается -1.0). }
  PyLong_AsDouble: function(obj: PPyObject): cdouble; cdecl;

  { PyLong_AsNativeBytes(v, buffer, n_bytes, flags) -> ssize_t
    Копирует целочисленное значение v в "нативную" переменную по адресу buffer.
    n_bytes — число доступных байт в buffer (0, чтобы запросить требуемый размер).
    flags — битовая маска Py_ASNATIVEBYTES_* (порядок байт, знаковость буфера,
    обработка отрицательных значений и не-int объектов).
    При исключении (например, TypeError или OverflowError) возвращает отрицательное значение.
    При успехе возвращает число байт, требуемое для представления значения (оно может быть
    больше n_bytes). Все n_bytes байт гарантированно заполняются (если нет исключения),
    поэтому игнорирование положительного результата эквивалентно даункасту C-значения. }
  PyLong_AsNativeBytes: function(v: PPyObject; buffer: Pointer; n_bytes: Py_ssize_t;
  flags: cint): Py_ssize_t; cdecl;

  { ----------------- Вспомогательные функции / утилиты ----------------- }
  { PyLong_AsInt(obj) -> int
    Удобный helper: конвертирует объект в C int, используя наиболее подходящую
    реализацию в зависимости от платформы. При ошибке (тип/переполнение) возвращает -1
    и устанавливает исключение — его необходимо обнаруживать через PyErr_Occurred(). }
  PyLong_AsInt: function(obj: PPyObject): cint; cdecl;

  { PyLong_AsInt32/AsUInt32/AsInt64/AsUInt64
    Конвертируют Python int в точные фиксированные целые типы C (int32_t/uint32_t/int64_t/uint64_t).
    value — указатель на переменную-результат; при успехе по нему записывается значение,
    а возвращаемое значение функции равно 0. При ошибке (например, переполнение или
    неподходящий тип) возвращается -1 и устанавливается соответствующее исключение
    (обычно TypeError или OverflowError). }
  PyLong_AsInt32: function(obj: PPyObject; Value: Pcint32): cint; cdecl;
  PyLong_AsUInt32: function(obj: PPyObject; Value: Pcuint32): cint; cdecl;
  PyLong_AsInt64: function(obj: PPyObject; Value: Pcint64): cint; cdecl;
  PyLong_AsUInt64: function(obj: PPyObject; Value: Pcuint64): cint; cdecl;

  { PyOS_strtoul / PyOS_strtol
    Вспомогательные функции парсинга строк, используемые CPython; похожи на stdlib strtoul/strtol,
    но могут иметь CPython-специфическое поведение на границах. }
  PyOS_strtoul: function(s: pansichar; endptr: PPAnsiChar; base: cint): culong; cdecl;
  PyOS_strtol: function(s: pansichar; endptr: PPAnsiChar; base: cint): clong; cdecl;

  { PyLong_GetInfo() -> namedtuple (readonly)
    Возвращает информацию о внутреннем представлении длинных целых в данной сборке Python,
    например: shift, base, digits, bits_in_digit и т.д. Полезно для кода, зависящего от представления. }
  PyLong_GetInfo: function(): PPyObject; cdecl;

  {$IFNDEF PY_LIMITED_API}
  { ----------------- Internal helpers (не часть Limited API) ----------------- }
  { _PyLong_Sign(v) -> int: >0 если положительное, 0 если ноль, <0 если отрицательное }
  _PyLong_Sign: function(v: PPyObject): cint; cdecl;

  { _PyLong_NumBits(v) -> Py_ssize_t: число значащих бит абсолютного значения v }
  _PyLong_NumBits: function(v: PPyObject): Py_ssize_t; cdecl;

  { Вспомогательные приватные функции для преобразования в/из байтового массива. }
  _PyLong_FromByteArray: function(bytes: pbyte; n: csize_t; little_endian: cint;
  is_signed: cint): PPyObject; cdecl;
  _PyLong_AsByteArray: function(v: PPyObject; bytes: pbyte; n: csize_t;
  little_endian: cint; is_signed: cint): cint; cdecl;

  { PyUnstable_Long_IsCompact(op) -> int: признак компактного представления (нестабильный API) }
  PyUnstable_Long_IsCompact: function(op: PPyLongObject): cint; cdecl;
  {$ENDIF}

  { ------------------------------------------------------------------ }
  { Inline-реализации C-макросов и других вспомогательных операций }
  { ------------------------------------------------------------------ }

{ Вспомогательные inline-функции для доступа к параметрам внутреннего представления int.
  В CPython PyLong_SHIFT/PyLong_BASE/PyLong_MASK и др. — это макросы, вычисляемые
  на этапе компиляции. Здесь мы извлекаем их значения из результата PyLong_GetInfo()
  один раз и кэшируем в статических переменных. }

function PyLong_SHIFT: cint; inline;
function PyLong_BASE: cint; inline;
function PyLong_MASK: cint; inline;
function PyLong_BITS_PER_DIGIT: cint; inline;

function PyLong_Check(op: PPyObject): cbool; inline;

implementation

{ Внутренний помощник: ленивое кэширование параметров long_info.
  При первом обращении вызывает PyLong_GetInfo(), извлекает интересующие
  поля и запоминает их в статических переменных. Далее возвращает
  уже вычисленные значения без повторных Python-вызовов. }
var
  { Кэш параметров long_info, полученных из PyLong_GetInfo().
    Значения и флаг инициализации хранятся на уровне модуля, чтобы избежать
    использования static-локальных переменных, отсутствующих в FPC. }
  _LongInfoCached: cbool = False;
  _LongInfoShift:  cint = -1;
  _LongInfoBase:   cint = -1;
  _LongInfoMask:   cint = -1;
  _LongInfoBitsPerDigit: cint = -1;

function _PyLong_GetInfoCached(out shift, base, mask, bits_per_digit: cint): cbool; inline;
var
  info, Value: PPyObject;
  got: cbool;
begin
  if _LongInfoCached then
  begin
    shift := _LongInfoShift;
    base  := _LongInfoBase;
    mask  := _LongInfoMask;
    bits_per_digit := _LongInfoBitsPerDigit;
    Exit(True);
  end;

  info := PyLong_GetInfo();
  if info = nil then
    Exit(False);

  got := True;

  Value := PyObject_GetAttrString(info, 'shift');
  if Value = nil then got := False
  else
    _LongInfoShift := PyLong_AsInt(Value);

  Value := PyObject_GetAttrString(info, 'base');
  if Value = nil then got := False
  else
    _LongInfoBase := PyLong_AsInt(Value);

  Value := PyObject_GetAttrString(info, 'mask');
  if Value = nil then got := False
  else
    _LongInfoMask := PyLong_AsInt(Value);

  Value := PyObject_GetAttrString(info, 'bits_per_digit');
  if Value = nil then got := False
  else
    _LongInfoBitsPerDigit := PyLong_AsInt(Value);

  if not got then
    Exit(False);

  _LongInfoCached := True;
  shift  := _LongInfoShift;
  base   := _LongInfoBase;
  mask   := _LongInfoMask;
  bits_per_digit := _LongInfoBitsPerDigit;
  Result := True;
end;

function PyLong_SHIFT: cint; inline;
var
  shift, base, mask, bits: cint;
begin
  if not _PyLong_GetInfoCached(shift, base, mask, bits) then
    Exit(-1);
  Result := shift;
end;

function PyLong_BASE: cint; inline;
var
  shift, base, mask, bits: cint;
begin
  if not _PyLong_GetInfoCached(shift, base, mask, bits) then
    Exit(-1);
  Result := base;
end;

function PyLong_MASK: cint; inline;
var
  shift, base, mask, bits: cint;
begin
  if not _PyLong_GetInfoCached(shift, base, mask, bits) then
    Exit(-1);
  Result := mask;
end;

function PyLong_BITS_PER_DIGIT: cint; inline;
var
  shift, base, mask, bits: cint;
begin
  if not _PyLong_GetInfoCached(shift, base, mask, bits) then
    Exit(-1);
  Result := bits;
end;

{ PyLong_Check(op) -> ненулевое, если op является PyLong или его подклассом }
function PyLong_Check(op: PPyObject): cbool; inline;
begin
  // Используем PyObject_TypeCheck (в python.pas) — она возвращает cbool.
  if op = nil then
  begin
    Result := False; // cbool: ложь
    Exit;
  end;
  Result := PyObject_TypeCheck(op, PyLong_Type);
end;

function PyLong_CheckExact(op: PPyObject): cbool; inline;
begin
  if (op = nil) or (op^.ob_type = nil) then
  begin
    Result := False;
    Exit;
  end;
  Result := cbool(op^.ob_type = PyLong_Type);
end;

function PyLong_IsZero(v: PPyObject): cint; inline;
begin
  {$IFNDEF PY_LIMITED_API}
  if Assigned(_PyLong_Sign) then
  begin
    if _PyLong_Sign(v) = 0 then Exit(1)
    else
      Exit(0);
  end;
  {$ENDIF}
  Result := -1; { недоступно }
end;

function PyLong_IsPositive(v: PPyObject): cint; inline;
begin
  {$IFNDEF PY_LIMITED_API}
  if Assigned(_PyLong_Sign) then
  begin
    if _PyLong_Sign(v) > 0 then Exit(1)
    else
      Exit(0);
  end;
  {$ENDIF}
  Result := -1;
end;

function PyLong_IsNegative(v: PPyObject): cint; inline;
begin
  {$IFNDEF PY_LIMITED_API}
  if Assigned(_PyLong_Sign) then
  begin
    if _PyLong_Sign(v) < 0 then Exit(1)
    else
      Exit(0);
  end;
  {$ENDIF}
  Result := -1;
end;

function PyLong_NumBits(v: PPyObject): Py_ssize_t; inline;
begin
  {$IFNDEF PY_LIMITED_API}
  if Assigned(_PyLong_NumBits) then
    Exit(_PyLong_NumBits(v));
  {$ENDIF}
  Result := -1;
end;

{ ---------------- Inline: PyLong_AsPid / PyLong_FromPid (репалтизация макросов) ---------------- }

function PyLong_AsPid(obj: PPyObject): clong; inline;
var
  tmp_ll: int64;
begin
  { Поведение: попытаться использовать наиболее подходящую функцию конверсии, в порядке
    предпочтения в зависимости от размеров типов. Если ничего не доступно — вернуть 0 }
  if Assigned(PyLong_AsSsize_t) and (SizeOf(clong) = SizeOf(Py_ssize_t)) then
  begin
    Exit(clong(PyLong_AsSsize_t(obj)));
  end;

  if Assigned(PyLong_AsLong) and (SizeOf(clong) = SizeOf(clong)) then
  begin
    Exit(PyLong_AsLong(obj));
  end;

  if Assigned(PyLong_AsLongLong) then
  begin
    tmp_ll := PyLong_AsLongLong(obj);
    Exit(clong(tmp_ll));
  end;

  Result := 0;
end;

function PyLong_FromPid(pid: clong): PPyObject; inline;
begin
  if Assigned(PyLong_FromSsize_t) and (SizeOf(clong) = SizeOf(Py_ssize_t)) then
  begin
    Exit(PyLong_FromSsize_t(Py_ssize_t(pid)));
  end;

  if Assigned(PyLong_FromLong) then
  begin
    Exit(PyLong_FromLong(pid));
  end;

  if Assigned(PyLong_FromLongLong) then
  begin
    Exit(PyLong_FromLongLong(pid));
  end;

  Result := nil;
end;

{ ---------------- Initialization: привязка экспортируемых символов ---------------- }
initialization
  Pointer(PyLong_Type) := GetProc('PyLong_Type');

  Pointer(PyLong_FromLong)    := GetProc('PyLong_FromLong');
  Pointer(PyLong_FromUnsignedLong) := GetProc('PyLong_FromUnsignedLong');
  Pointer(PyLong_FromSize_t)  := GetProc('PyLong_FromSize_t');
  Pointer(PyLong_FromSsize_t) := GetProc('PyLong_FromSsize_t');
  Pointer(PyLong_FromDouble)  := GetProc('PyLong_FromDouble');

  Pointer(PyLong_FromNativeBytes) := GetProc('PyLong_FromNativeBytes');
  Pointer(PyLong_FromUnsignedNativeBytes) := GetProc('PyLong_FromUnsignedNativeBytes');

  Pointer(PyLong_FromString) := GetProc('PyLong_FromString');
  Pointer(PyLong_FromUnicodeObject) := GetProc('PyLong_FromUnicodeObject');

  Pointer(PyLong_FromVoidPtr) := GetProc('PyLong_FromVoidPtr');

  Pointer(PyLong_FromLongLong) := GetProc('PyLong_FromLongLong');

  Pointer(PyLong_FromInt32)  := GetProc('PyLong_FromInt32');
  Pointer(PyLong_FromUInt32) := GetProc('PyLong_FromUInt32');
  Pointer(PyLong_FromInt64)  := GetProc('PyLong_FromInt64');
  Pointer(PyLong_FromUInt64) := GetProc('PyLong_FromUInt64');

  Pointer(PyLong_AsLong)    := GetProc('PyLong_AsLong');
  Pointer(PyLong_AsLongAndOverflow) := GetProc('PyLong_AsLongAndOverflow');
  Pointer(PyLong_AsSsize_t) := GetProc('PyLong_AsSsize_t');
  Pointer(PyLong_AsSize_t)  := GetProc('PyLong_AsSize_t');
  Pointer(PyLong_AsUnsignedLong) := GetProc('PyLong_AsUnsignedLong');
  Pointer(PyLong_AsUnsignedLongMask) := GetProc('PyLong_AsUnsignedLongMask');

  Pointer(PyLong_AsInt)      := GetProc('PyLong_AsInt');
  Pointer(PyLong_AsInt32)    := GetProc('PyLong_AsInt32');
  Pointer(PyLong_AsUInt32)   := GetProc('PyLong_AsUInt32');
  Pointer(PyLong_AsInt64)    := GetProc('PyLong_AsInt64');
  Pointer(PyLong_AsUInt64)   := GetProc('PyLong_AsUInt64');
  Pointer(PyLong_AsNativeBytes) := GetProc('PyLong_AsNativeBytes');
  Pointer(PyLong_AsLongLong) := GetProc('PyLong_AsLongLong');
  Pointer(PyLong_AsLongLongAndOverflow) := GetProc('PyLong_AsLongLongAndOverflow');
  Pointer(PyLong_AsUnsignedLongLong) := GetProc('PyLong_AsUnsignedLongLong');
  Pointer(PyLong_AsUnsignedLongLongMask) := GetProc('PyLong_AsUnsignedLongLongMask');

  Pointer(PyLong_AsDouble) := GetProc('PyLong_AsDouble');

  Pointer(PyLong_AsVoidPtr) := GetProc('PyLong_AsVoidPtr');

  Pointer(PyOS_strtoul) := GetProc('PyOS_strtoul');
  Pointer(PyOS_strtol)  := GetProc('PyOS_strtol');

  Pointer(PyLong_GetInfo) := GetProc('PyLong_GetInfo');

  {$IFNDEF PY_LIMITED_API}
  Pointer(_PyLong_Sign)    := GetProc('_PyLong_Sign');
  Pointer(_PyLong_NumBits) := GetProc('_PyLong_NumBits');
  Pointer(_PyLong_FromByteArray) := GetProc('_PyLong_FromByteArray');
  Pointer(_PyLong_AsByteArray) := GetProc('_PyLong_AsByteArray');
  Pointer(PyUnstable_Long_IsCompact) := GetProc('PyUnstable_Long_IsCompact');
  {$ENDIF}
end.
