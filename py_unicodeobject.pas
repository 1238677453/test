{$mode fpc}
{$I config.inc}
unit py_unicodeobject;

interface

uses
  ctypes, python;



{ ==================================================================
  Простой биндинг для CPython Include/unicodeobject.h (ветка main, 3.14)

  Цели модуля:
  - предоставить Pascal-объявления основных Unicode API-функций CPython;
  - учесть Py_LIMITED_API и прочие флаги через условную компиляцию;
  - оформить публичные функции как процедурные переменные (var) для
    динамической привязки через GetProc (см. py_common / python.pas);

  Модуль не претендует на полную вычитку unicodeobject.h, но покрывает
  наиболее часто используемый публичный API для работы со строками.
  ================================================================== }

var
  { Типы }
  { Тип unicode-объекта str в CPython. }
  PyUnicode_Type:     PPyTypeObject;
  { Тип итератора по unicode-строке. }
  PyUnicodeIter_Type: PPyTypeObject;

  { ----------------- Базовые конструкторы ----------------- }
  { PyUnicode_FromStringAndSize(u, size) -> new str
    Создаёт Unicode-строку из буфера UTF-8 длиной size байт. }
  PyUnicode_FromStringAndSize: function(const u: pansichar; size: Py_ssize_t): PPyObject; cdecl;

  { PyUnicode_FromString(u) -> new str
    Создаёт Unicode-строку из null-терминированной UTF-8 строки u. }
  PyUnicode_FromString: function(const u: pansichar): PPyObject; cdecl;

  { PyUnicode_FromEncodedObject(obj, encoding, errors) -> new str
    Декодирует bytes/bytearray/bytes-like объект obj с указанной кодировкой
    encoding и политикой ошибок errors. При encoding=nil используется UTF-8,
    при errors=nil — "strict". Возвращает new reference или nil при ошибке. }
  PyUnicode_FromEncodedObject: function(obj: PPyObject;
  const encoding, errors: pansichar): PPyObject; cdecl;

  { PyUnicode_FromObject(obj) -> new str
    Гарантированно возвращает настоящий Unicode-объект (str):
    - если obj уже str (не подкласс) — увеличивает refcount и возвращает его;
    - если подкласс str — создаёт настоящий str с теми же данными. }
  PyUnicode_FromObject: function(obj: PPyObject): PPyObject; cdecl;

  { PyUnicode_FromFormat/FromFormatV
    Форматирующие функции в стиле printf, возвращают Unicode-строку. }
  PyUnicode_FromFormatV: function(const fmt: pansichar; vargs: Pointer): PPyObject; cdecl;
  PyUnicode_FromFormat: function(const fmt: pansichar): PPyObject; cdecl; varargs;

  { Интернирование строк }
  PyUnicode_InternInPlace: procedure(var s: PPyObject); cdecl;
  PyUnicode_InternFromString: function(const u: pansichar): PPyObject; cdecl;

  { ----------------- Доступ к UCS4 / длине / символам ----------------- }

  {$IFNDEF PY_LIMITED_API}
  { PyUnicode_Substring(str, start, end) -> new str }
  PyUnicode_Substring: function(str: PPyObject; start, _end: Py_ssize_t): PPyObject; cdecl;

  { PyUnicode_AsUCS4(unicode, buffer, buflen, copy_null) -> Py_UCS4*
    Копирует содержимое строки в UCS4-буфер. }
  PyUnicode_AsUCS4: function(unicode: PPyObject; buffer: PPy_UCS4;
  buflen: Py_ssize_t; copy_null: cint): PPy_UCS4; cdecl;

  { PyUnicode_AsUCS4Copy(unicode) -> Py_UCS4* (через PyMem_Malloc). }
  PyUnicode_AsUCS4Copy: function(unicode: PPyObject): PPy_UCS4; cdecl;

  { PyUnicode_GetLength(unicode) -> Py_ssize_t }
  PyUnicode_GetLength: function(unicode: PPyObject): Py_ssize_t; cdecl;

  { PyUnicode_ReadChar(unicode, index) -> Py_UCS4 }
  PyUnicode_ReadChar: function(unicode: PPyObject; index: Py_ssize_t): Py_UCS4; cdecl;

  { PyUnicode_WriteChar(unicode, index, ch) -> int }
  PyUnicode_WriteChar: function(unicode: PPyObject; index: Py_ssize_t;
  character: Py_UCS4): cint; cdecl;
  {$ENDIF}

  { PyUnicode_Resize(&unicode, length) -> int
    Изменяет длину unicode (в кодовых точках). При ошибке возвращает -1 и
    оставляет *unicode нетронутым. }
  PyUnicode_Resize: function(var unicode: PPyObject; length: Py_ssize_t): cint; cdecl;

  { ----------------- WChar API (зависит от наличия wchar_t) ----------------- }

  {$IFDEF HAVE_WCHAR_H}
  PyUnicode_FromWideChar: function(const w: PWideChar; size: Py_ssize_t): PPyObject; cdecl;
  PyUnicode_AsWideChar: function(unicode: PPyObject; w: PWideChar;
    size: Py_ssize_t): Py_ssize_t; cdecl;
  PyUnicode_AsWideCharString: function(unicode: PPyObject;
    size: PPy_ssize_t): PWideChar; cdecl;
  {$ENDIF}

  { ----------------- Ordinal / 기본 функции ----------------- }

  { PyUnicode_FromOrdinal(ordinal) -> new str из одного символа }
  PyUnicode_FromOrdinal: function(ordinal: cint): PPyObject; cdecl;

  { ----------------- Generic codecs / UTF-8 / др. ----------------- }

  { PyUnicode_GetDefaultEncoding() -> const char* (обычно "utf-8"). }
  PyUnicode_GetDefaultEncoding: function: pansichar; cdecl;

  {Generic decode/encode}
  PyUnicode_Decode: function(const s: pansichar; size: Py_ssize_t;
  const encoding, errors: pansichar): PPyObject; cdecl;
  PyUnicode_AsEncodedString: function(unicode: PPyObject;
  const encoding, errors: pansichar): PPyObject; cdecl;
  PyUnicode_BuildEncodingMap: function(string_: PPyObject): PPyObject; cdecl;

  { UTF-7, UTF-8, UTF-16/32, Unicode-Escape, Raw-Unicode-Escape, Latin-1, ASCII }

  PyUnicode_DecodeUTF7: function(const s: pansichar; length: Py_ssize_t;
  const errors: pansichar): PPyObject; cdecl;
  PyUnicode_DecodeUTF7Stateful: function(const s: pansichar; length: Py_ssize_t;
  const errors: pansichar; consumed: PPy_ssize_t): PPyObject; cdecl;

  PyUnicode_DecodeUTF8: function(const s: pansichar; length: Py_ssize_t;
  const errors: pansichar): PPyObject; cdecl;
  PyUnicode_DecodeUTF8Stateful: function(const s: pansichar; length: Py_ssize_t;
  const errors: pansichar; consumed: PPy_ssize_t): PPyObject; cdecl;
  PyUnicode_AsUTF8String: function(unicode: PPyObject): PPyObject; cdecl;

  {$IFNDEF PY_LIMITED_API}
  PyUnicode_AsUTF8AndSize: function(unicode: PPyObject; size: PPy_ssize_t): pansichar; cdecl;
  {$ENDIF}

  PyUnicode_DecodeUTF32: function(const s: pansichar; length: Py_ssize_t;
  const errors: pansichar; byteorder: Pcint): PPyObject; cdecl;
  PyUnicode_DecodeUTF32Stateful: function(const s: pansichar; length: Py_ssize_t;
  const errors: pansichar; byteorder: Pcint; consumed: PPy_ssize_t): PPyObject; cdecl;
  PyUnicode_AsUTF32String: function(unicode: PPyObject): PPyObject; cdecl;

  PyUnicode_DecodeUTF16: function(const s: pansichar; length: Py_ssize_t;
  const errors: pansichar; byteorder: Pcint): PPyObject; cdecl;
  PyUnicode_DecodeUTF16Stateful: function(const s: pansichar; length: Py_ssize_t;
  const errors: pansichar; byteorder: Pcint; consumed: PPy_ssize_t): PPyObject; cdecl;
  PyUnicode_AsUTF16String: function(unicode: PPyObject): PPyObject; cdecl;

  PyUnicode_DecodeUnicodeEscape: function(const s: pansichar; length: Py_ssize_t;
  const errors: pansichar): PPyObject; cdecl;
  PyUnicode_AsUnicodeEscapeString: function(unicode: PPyObject): PPyObject; cdecl;

  PyUnicode_DecodeRawUnicodeEscape: function(const s: pansichar; length: Py_ssize_t;
  const errors: pansichar): PPyObject; cdecl;
  PyUnicode_AsRawUnicodeEscapeString: function(unicode: PPyObject): PPyObject; cdecl;

  PyUnicode_DecodeLatin1: function(const s: pansichar; length: Py_ssize_t;
  const errors: pansichar): PPyObject; cdecl;
  PyUnicode_AsLatin1String: function(unicode: PPyObject): PPyObject; cdecl;

  PyUnicode_DecodeASCII: function(const s: pansichar; length: Py_ssize_t;
  const errors: pansichar): PPyObject; cdecl;
  PyUnicode_AsASCIIString: function(unicode: PPyObject): PPyObject; cdecl;

  PyUnicode_DecodeCharmap: function(const s: pansichar; length: Py_ssize_t;
  mapping: PPyObject; const errors: pansichar): PPyObject; cdecl;
  PyUnicode_AsCharmapString: function(unicode, mapping: PPyObject): PPyObject; cdecl;

  {$IFDEF MSWINDOWS}
  PyUnicode_DecodeMBCS: function(const s: pansichar; length: Py_ssize_t;
  const errors: pansichar): PPyObject; cdecl;
  PyUnicode_DecodeMBCSStateful: function(const s: pansichar; length: Py_ssize_t;
  const errors: pansichar; consumed: PPy_ssize_t): PPyObject; cdecl;
  {$IFNDEF PY_LIMITED_API}
  PyUnicode_DecodeCodePageStateful: function(code_page: cint; const s: pansichar;
  length: Py_ssize_t; const errors: pansichar; consumed: PPy_ssize_t): PPyObject; cdecl;
  PyUnicode_EncodeCodePage: function(code_page: cint; unicode: PPyObject;
  const errors: pansichar): PPyObject; cdecl;
  {$ENDIF}
  PyUnicode_AsMBCSString: function(unicode: PPyObject): PPyObject; cdecl;
  {$ENDIF}

  {$IFNDEF PY_LIMITED_API}
  { Locale / FS encoding }
  PyUnicode_DecodeLocaleAndSize: function(const str: pansichar; len: Py_ssize_t;
  const errors: pansichar): PPyObject; cdecl;
  PyUnicode_DecodeLocale: function(const str, errors: pansichar): PPyObject; cdecl;
  PyUnicode_EncodeLocale:   function(unicode: PPyObject;
  const errors: pansichar): PPyObject; cdecl;
  {$ENDIF}

  PyUnicode_FSConverter: function(obj: PPyObject; dst: Pointer): cint; cdecl;
  PyUnicode_FSDecoder: function(obj: PPyObject; dst: Pointer): cint; cdecl;
  PyUnicode_DecodeFSDefault: function(const s: pansichar): PPyObject; cdecl;
  PyUnicode_DecodeFSDefaultAndSize: function(const s: pansichar;
  size: Py_ssize_t): PPyObject; cdecl;
  PyUnicode_EncodeFSDefault: function(unicode: PPyObject): PPyObject; cdecl;

  { ----------------- Операции над строками ----------------- }

  PyUnicode_Concat: function(left, right: PPyObject): PPyObject; cdecl;
  PyUnicode_Append: procedure(var left: PPyObject; right: PPyObject); cdecl;
  PyUnicode_AppendAndDel: procedure(var left: PPyObject; right: PPyObject); cdecl;

  PyUnicode_Split: function(s, sep: PPyObject; maxsplit: Py_ssize_t): PPyObject; cdecl;
  PyUnicode_Splitlines: function(s: PPyObject; keepends: cint): PPyObject; cdecl;
  PyUnicode_Partition: function(s, sep: PPyObject): PPyObject; cdecl;
  PyUnicode_RPartition: function(s, sep: PPyObject): PPyObject; cdecl;
  PyUnicode_RSplit: function(s, sep: PPyObject; maxsplit: Py_ssize_t): PPyObject; cdecl;

  PyUnicode_Translate:      function(str_, table: PPyObject;
  const errors: pansichar): PPyObject; cdecl;
  PyUnicode_Join: function(separator, seq: PPyObject): PPyObject; cdecl;

  PyUnicode_Tailmatch: function(str_, substr: PPyObject; start, _end: Py_ssize_t;
  direction: cint): Py_ssize_t; cdecl;
  PyUnicode_Find: function(str_, substr: PPyObject; start, _end: Py_ssize_t;
  direction: cint): Py_ssize_t; cdecl;

  {$IFNDEF PY_LIMITED_API}
  PyUnicode_FindChar: function(str_: PPyObject; ch: Py_UCS4; start, _end: Py_ssize_t;
  direction: cint): Py_ssize_t; cdecl;
  {$ENDIF}

  PyUnicode_Count: function(str_, substr: PPyObject;
  start, _end: Py_ssize_t): Py_ssize_t; cdecl;
  PyUnicode_Replace:     function(str_, substr, replstr: PPyObject;
  maxcount: Py_ssize_t): PPyObject; cdecl;

  PyUnicode_Compare: function(left, right: PPyObject): cint; cdecl;
  PyUnicode_CompareWithASCIIString: function(left: PPyObject;
  const right: pansichar): cint; cdecl;
  {$IFNDEF PY_LIMITED_API}
  PyUnicode_EqualToUTF8: function(left: PPyObject; const right: pansichar): cint; cdecl;
  {$ENDIF}

  { ------------------------------------------------------------------ }
  { Дополнительные Pascal-хелперы (inline) }
  { ------------------------------------------------------------------ }

function PyUnicode_Check(op: PPyObject): cbool; inline;
function PyUnicode_CheckExact(op: PPyObject): cbool; inline;


implementation

function PyUnicode_Check(op: PPyObject): cbool; inline;
begin
  if (op = nil) or (PyUnicode_Type = nil) then
    Exit(False);
  Result := PyObject_TypeCheck(op, PyUnicode_Type);
end;

function PyUnicode_CheckExact(op: PPyObject): cbool; inline;
begin
  if (op = nil) or (op^.ob_type = nil) or (PyUnicode_Type = nil) then
    Exit(False);
  Result := cbool(op^.ob_type = PyUnicode_Type);
end;

initialization

  Pointer(PyUnicode_Type)     := GetProc('PyUnicode_Type');
  Pointer(PyUnicodeIter_Type) := GetProc('PyUnicodeIter_Type');

  Pointer(PyUnicode_FromStringAndSize) := GetProc('PyUnicode_FromStringAndSize');
  Pointer(PyUnicode_FromString)    := GetProc('PyUnicode_FromString');
  Pointer(PyUnicode_FromEncodedObject) := GetProc('PyUnicode_FromEncodedObject');
  Pointer(PyUnicode_FromObject)    := GetProc('PyUnicode_FromObject');
  Pointer(PyUnicode_FromFormatV)   := GetProc('PyUnicode_FromFormatV');
  Pointer(PyUnicode_FromFormat)    := GetProc('PyUnicode_FromFormat');
  Pointer(PyUnicode_InternInPlace) := GetProc('PyUnicode_InternInPlace');
  Pointer(PyUnicode_InternFromString) := GetProc('PyUnicode_InternFromString');

  {$IFNDEF PY_LIMITED_API}
  Pointer(PyUnicode_Substring)  := GetProc('PyUnicode_Substring');
  Pointer(PyUnicode_AsUCS4)     := GetProc('PyUnicode_AsUCS4');
  Pointer(PyUnicode_AsUCS4Copy) := GetProc('PyUnicode_AsUCS4Copy');
  Pointer(PyUnicode_GetLength)  := GetProc('PyUnicode_GetLength');
  Pointer(PyUnicode_ReadChar)   := GetProc('PyUnicode_ReadChar');
  Pointer(PyUnicode_WriteChar)  := GetProc('PyUnicode_WriteChar');
  {$ENDIF}

  Pointer(PyUnicode_Resize) := GetProc('PyUnicode_Resize');

  {$IFDEF HAVE_WCHAR_H}
  Pointer(PyUnicode_FromWideChar) := GetProc('PyUnicode_FromWideChar');
  Pointer(PyUnicode_AsWideChar) := GetProc('PyUnicode_AsWideChar');
  Pointer(PyUnicode_AsWideCharString) := GetProc('PyUnicode_AsWideCharString');
  {$ENDIF}

  Pointer(PyUnicode_FromOrdinal) := GetProc('PyUnicode_FromOrdinal');

  Pointer(PyUnicode_GetDefaultEncoding) := GetProc('PyUnicode_GetDefaultEncoding');
  Pointer(PyUnicode_Decode) := GetProc('PyUnicode_Decode');
  Pointer(PyUnicode_AsEncodedString) := GetProc('PyUnicode_AsEncodedString');
  Pointer(PyUnicode_BuildEncodingMap) := GetProc('PyUnicode_BuildEncodingMap');

  Pointer(PyUnicode_DecodeUTF7)    := GetProc('PyUnicode_DecodeUTF7');
  Pointer(PyUnicode_DecodeUTF7Stateful) := GetProc('PyUnicode_DecodeUTF7Stateful');
  Pointer(PyUnicode_DecodeUTF8)    := GetProc('PyUnicode_DecodeUTF8');
  Pointer(PyUnicode_DecodeUTF8Stateful) := GetProc('PyUnicode_DecodeUTF8Stateful');
  Pointer(PyUnicode_AsUTF8String)  := GetProc('PyUnicode_AsUTF8String');
  {$IFNDEF PY_LIMITED_API}
  Pointer(PyUnicode_AsUTF8AndSize) := GetProc('PyUnicode_AsUTF8AndSize');
  {$ENDIF}

  Pointer(PyUnicode_DecodeUTF32)   := GetProc('PyUnicode_DecodeUTF32');
  Pointer(PyUnicode_DecodeUTF32Stateful) := GetProc('PyUnicode_DecodeUTF32Stateful');
  Pointer(PyUnicode_AsUTF32String) := GetProc('PyUnicode_AsUTF32String');

  Pointer(PyUnicode_DecodeUTF16)   := GetProc('PyUnicode_DecodeUTF16');
  Pointer(PyUnicode_DecodeUTF16Stateful) := GetProc('PyUnicode_DecodeUTF16Stateful');
  Pointer(PyUnicode_AsUTF16String) := GetProc('PyUnicode_AsUTF16String');

  Pointer(PyUnicode_DecodeUnicodeEscape)      := GetProc('PyUnicode_DecodeUnicodeEscape');
  Pointer(PyUnicode_AsUnicodeEscapeString)    := GetProc('PyUnicode_AsUnicodeEscapeString');
  Pointer(PyUnicode_DecodeRawUnicodeEscape)   := GetProc('PyUnicode_DecodeRawUnicodeEscape');
  Pointer(PyUnicode_AsRawUnicodeEscapeString) := GetProc('PyUnicode_AsRawUnicodeEscapeString');

  Pointer(PyUnicode_DecodeLatin1)    := GetProc('PyUnicode_DecodeLatin1');
  Pointer(PyUnicode_AsLatin1String)  := GetProc('PyUnicode_AsLatin1String');
  Pointer(PyUnicode_DecodeASCII)     := GetProc('PyUnicode_DecodeASCII');
  Pointer(PyUnicode_AsASCIIString)   := GetProc('PyUnicode_AsASCIIString');
  Pointer(PyUnicode_DecodeCharmap)   := GetProc('PyUnicode_DecodeCharmap');
  Pointer(PyUnicode_AsCharmapString) := GetProc('PyUnicode_AsCharmapString');

  {$IFDEF MSWINDOWS}
  Pointer(PyUnicode_DecodeMBCS)     := GetProc('PyUnicode_DecodeMBCS');
  Pointer(PyUnicode_DecodeMBCSStateful) := GetProc('PyUnicode_DecodeMBCSStateful');
  {$IFNDEF PY_LIMITED_API}
  Pointer(PyUnicode_DecodeCodePageStateful) := GetProc('PyUnicode_DecodeCodePageStateful');
  Pointer(PyUnicode_EncodeCodePage) := GetProc('PyUnicode_EncodeCodePage');
  {$ENDIF}
  Pointer(PyUnicode_AsMBCSString)   := GetProc('PyUnicode_AsMBCSString');
  {$ENDIF}

  {$IFNDEF PY_LIMITED_API}
  Pointer(PyUnicode_DecodeLocaleAndSize) := GetProc('PyUnicode_DecodeLocaleAndSize');
  Pointer(PyUnicode_DecodeLocale) := GetProc('PyUnicode_DecodeLocale');
  Pointer(PyUnicode_EncodeLocale) := GetProc('PyUnicode_EncodeLocale');
  {$ENDIF}

  Pointer(PyUnicode_FSConverter) := GetProc('PyUnicode_FSConverter');
  Pointer(PyUnicode_FSDecoder)   := GetProc('PyUnicode_FSDecoder');
  Pointer(PyUnicode_DecodeFSDefault) := GetProc('PyUnicode_DecodeFSDefault');
  Pointer(PyUnicode_DecodeFSDefaultAndSize) := GetProc('PyUnicode_DecodeFSDefaultAndSize');
  Pointer(PyUnicode_EncodeFSDefault) := GetProc('PyUnicode_EncodeFSDefault');

  Pointer(PyUnicode_Concat)    := GetProc('PyUnicode_Concat');
  Pointer(PyUnicode_Append)    := GetProc('PyUnicode_Append');
  Pointer(PyUnicode_AppendAndDel) := GetProc('PyUnicode_AppendAndDel');
  Pointer(PyUnicode_Split)     := GetProc('PyUnicode_Split');
  Pointer(PyUnicode_Splitlines) := GetProc('PyUnicode_Splitlines');
  Pointer(PyUnicode_Partition) := GetProc('PyUnicode_Partition');
  Pointer(PyUnicode_RPartition) := GetProc('PyUnicode_RPartition');
  Pointer(PyUnicode_RSplit)    := GetProc('PyUnicode_RSplit');
  Pointer(PyUnicode_Translate) := GetProc('PyUnicode_Translate');
  Pointer(PyUnicode_Join)      := GetProc('PyUnicode_Join');
  Pointer(PyUnicode_Tailmatch) := GetProc('PyUnicode_Tailmatch');
  Pointer(PyUnicode_Find)      := GetProc('PyUnicode_Find');
  {$IFNDEF PY_LIMITED_API}
  Pointer(PyUnicode_FindChar)  := GetProc('PyUnicode_FindChar');
  {$ENDIF}
  Pointer(PyUnicode_Count)     := GetProc('PyUnicode_Count');
  Pointer(PyUnicode_Replace)   := GetProc('PyUnicode_Replace');
  Pointer(PyUnicode_Compare)   := GetProc('PyUnicode_Compare');
  Pointer(PyUnicode_CompareWithASCIIString) := GetProc('PyUnicode_CompareWithASCIIString');
  {$IFNDEF PY_LIMITED_API}
  Pointer(PyUnicode_EqualToUTF8) := GetProc('PyUnicode_EqualToUTF8');
  {$ENDIF}
end.
