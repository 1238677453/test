{
Главный заголовочный файл для работы с Python C API в Free Pascal

Этот модуль содержит ,основные декларации и типы Python C API. Он обеспечивает
кроссплатформенную совместимость для Windows (.pyd), Linux (.so) и
macOS (.dylib).

Целевая версия Python: 3.14
Ограниченный функционал 3.13 поддерживается через условную компиляцию  Python313
No_GIL версия поддерживается через условную компиляцию  Py_GIL_DISABLED
Только базовый функционал поддерживается через условную компиляцию Py_LIMITED_API
Встроенные и портабельные версии питона поддерживаютя через условную компиляцию Py_PORTABLE
"Устаревший" на момент 3.14 функционал не поддерживается вообще
}
{$mode fpc}
{$I config.inc}// ключи компиляции
unit python;

interface

uses
  ctypes;

const

  { Версия C API, используемая при создании модуля }
  PYTHON_API_VERSION = 1013;

  { идентификаторы поддерживаемых библиотек }
  {$IFDEF MSWINDOWS}
  PythonFullNameAr: array [0..1] of pansichar = ('python313.dll', 'python314.dll');
  {$ELSE}
  {$IFDEF DARWIN}
  PythonFullNameAr: array [0..1] of pansichar = ('libpython313.dylib', 'libpython314.dylib');
  {$ELSE}
  {$IFDEF LINUX}
  PythonFullNameAr: array [0..1] of pansichar = ('libpython313.so', 'libpython314.so');
  {$ELSE}
  PythonFullNameAr: array [0..1] of pansichar = ('libpython313.so', 'libpython314.so');
  {$ENDIF}
  {$ENDIF}
  {$ENDIF}

  // ----------------------Объявления типов C-----------------------------
type

  uint8_t    = byte;
  puint8_t   = uint8_t;
  uint16_t   = word;
  puint16_t  = uint16_t;
  uint32_t   = cardinal;
  puint32_t  = ^uint32_t;
  uint64_t   = int64;
  puint64_t  = ^uint64_t;
  uintptr_t  = nativeuint;
  puintptr_t = ^uintptr_t;


  // ------------------ Объявления типов CPython---------------------------

  Py_ssize_t  = nativeint;
  PPy_ssize_t = ^Py_ssize_t;
  Py_hash_t   = Py_ssize_t;
  Py_UCS1     = uint8_t;
  PPy_UCS1    = ^Py_UCS1;
  Py_UCS2     = uint16_t;
  PPy_UCS2    = ^Py_UCS2;
  Py_UCS4     = uint32_t;
  PPy_UCS4    = ^Py_UCS4;
  PyGILState_STATE = cint;

const

{
Флаги вызова методов (`ml_flags`)
Определяют сигнатуру C-функции, реализующей метод
}
  { Метод принимает аргументы в виде кортежа (varargs). Сигнатура: `PyCFunction` }
  METH_VARARGS = $0001;
  { Метод принимает именованные аргументы (kwargs). Сигнатура: `PyCFunctionWithKeywords` }
  METH_KEYWORDS = $0002;
  { Метод не принимает аргументов. Сигнатура: `PyCFunction` }
  METH_NOARGS = $0004;
  { Метод принимает один объект в качестве аргумента. Сигнатура: `PyCFunction` }
  METH_O = $0008;


{
Флаги типа (tp_flags)
Определяют возможности и поведение типа
  Эти флаги используются для изменения ожидаемых возможностей и поведения
  конкретного типа. Большинство флагов было удалено в Python 3.0, чтобы
  освободить место для новых. При определении типа следует использовать
  `Py_TPFLAGS_DEFAULT`. Проверить наличие флага можно с помощью
  `PyType_HasFeature(type_ob, flag_value)`.
}
  {$IFNDEF PY_LIMITED_API}
  { Отслеживает типы, инициализированные через `_PyStaticType_InitBuiltin` }
  _Py_TPFLAGS_STATIC_BUILTIN = 1 shl 1;
  { Массив значений размещён встраиваемо сразу после объекта. Подразумевает `Py_TPFLAGS_HAVE_GC` }
  Py_TPFLAGS_INLINE_VALUES = 1 shl 2;
  { Размещение weakref-указателей управляется ВМ. Подразумевает `Py_TPFLAGS_HAVE_GC` }
  Py_TPFLAGS_MANAGED_WEAKREF = 1 shl 3;
  { Размещение dict-указателей управляется ВМ. Подразумевает `Py_TPFLAGS_HAVE_GC` }
  Py_TPFLAGS_MANAGED_DICT = 1 shl 4;
  { Тип имеет управляемые ВМ указатели dict или weakref }
  Py_TPFLAGS_PREHEADER = Py_TPFLAGS_MANAGED_WEAKREF or Py_TPFLAGS_MANAGED_DICT;
  { Экземпляры типа обрабатываются как последовательности при сопоставлении с шаблоном }
  Py_TPFLAGS_SEQUENCE  = 1 shl 5;
  { Экземпляры типа обрабатываются как отображения при сопоставлении с шаблоном }
  Py_TPFLAGS_MAPPING   = 1 shl 6;
  {$ENDIF}
  { Запрещает создание экземпляров типа (`tp_new` = `nil`) }
  Py_TPFLAGS_DISALLOW_INSTANTIATION = 1 shl 7;
  { Тип объекта неизменяемый: атрибуты нельзя установить или удалить }
  Py_TPFLAGS_IMMUTABLETYPE = 1 shl 8;
  { Тип объекта динамически размещён (создан в "куче") }
  Py_TPFLAGS_HEAPTYPE  = 1 shl 9;
  { Тип допускает создание подклассов }
  Py_TPFLAGS_BASETYPE  = 1 shl 10;
  { Тип реализует протокол vectorcall (PEP 590) }
  {$IFNDEF PY_LIMITED_API}
  Py_TPFLAGS_HAVE_VECTORCALL = 1 shl 11;
  _Py_TPFLAGS_HAVE_VECTORCALL = Py_TPFLAGS_HAVE_VECTORCALL;
  {$ENDIF}
  { Тип «готов» — полностью инициализирован }
  Py_TPFLAGS_READY     = 1 shl 12;
  { Тип находится в процессе «подготовки», для предотвращения рекурсии }
  Py_TPFLAGS_READYING  = 1 shl 13;
  { Объекты поддерживают сборку мусора }
  Py_TPFLAGS_HAVE_GC   = 1 shl 14;
  { Зарезервировано для Stackless Python }
  {$ifdef STACKLESS}
  Py_TPFLAGS_HAVE_STACKLESS_EXTENSION = 3 shl 15;
  {$else}
  Py_TPFLAGS_HAVE_STACKLESS_EXTENSION = 0;
  {$endif}
  { Объекты ведут себя как несвязанный метод }
  Py_TPFLAGS_METHOD_DESCRIPTOR = 1 shl 17;
  { Неиспользуемый устаревший флаг }
  Py_TPFLAGS_VALID_VERSION_TAG = 1 shl 19;
  { Тип является абстрактным и не может быть инстанцирован }
  Py_TPFLAGS_IS_ABSTRACT = 1 shl 20;
  { Недокументированный флаг для особого поведения встроенных типов при сопоставлении с шаблоном }
  _Py_TPFLAGS_MATCH_SELF = 1 shl 22;
  { Элементы (`ob_size`*`tp_itemsize`) находятся в конце экземпляра }
  Py_TPFLAGS_ITEMS_AT_END = 1 shl 23;

{
Флаги для определения подклассов
Используются для быстрой проверки наследования от базовых типов
}
  Py_TPFLAGS_LONG_SUBCLASS     = 1 shl 24;
  Py_TPFLAGS_LIST_SUBCLASS     = 1 shl 25;
  Py_TPFLAGS_TUPLE_SUBCLASS    = 1 shl 26;
  Py_TPFLAGS_BYTES_SUBCLASS    = 1 shl 27;
  Py_TPFLAGS_UNICODE_SUBCLASS  = 1 shl 28;
  Py_TPFLAGS_DICT_SUBCLASS     = 1 shl 29;
  Py_TPFLAGS_BASE_EXC_SUBCLASS = 1 shl 30;
  Py_TPFLAGS_TYPE_SUBCLASS     = 1 shl 31;

  { Флаги по умолчанию для нового типа }
  Py_TPFLAGS_DEFAULT = Py_TPFLAGS_HAVE_STACKLESS_EXTENSION;

{Флаги для обратной совместимости
  Эти флаги сохранены для совместимости со старыми расширениями,
  использующими стабильный ABI. Биты не должны использоваться повторно.
}
  { Указывает на наличие поля `tp_finalize` }
  Py_TPFLAGS_HAVE_FINALIZE    = 1 shl 0;
  { Указывает на наличие поля `tp_version_tag` }
  Py_TPFLAGS_HAVE_VERSION_TAG = 1 shl 18;

type

  //Объявления указателей для типов
  PPyTypeObject = ^PyTypeObject;
  PPyObject     = ^PyObject;
  PPPyObject    = ^PPyObject;
  PPy_buffer    = ^Py_buffer;

  //Вспомогательные типы-функции
  PyCFunction = function(self, args: PPyObject): PPyObject; cdecl;
  getter = function(obj: PPyObject; closure: Pointer): PPyObject; cdecl;
  setter = function(obj: PPyObject; Value: PPyObject; closure: Pointer): cint; cdecl;
  pydestructor = procedure(ob: PPyObject); cdecl;
  getattrfunc = function(ob1: PPyObject; Name: pansichar): PPyObject; cdecl;
  setattrfunc = function(ob1: PPyObject; Name: pansichar; ob2: PPyObject): cint; cdecl;
  reprfunc = function(ob: PPyObject): PPyObject; cdecl;
  hashfunc = function(ob: PPyObject): Py_hash_t; cdecl;
  ternaryfunc = function(ob1, ob2, ob3: PPyObject): PPyObject; cdecl;
  getattrofunc = function(ob1, ob2: PPyObject): PPyObject; cdecl;
  setattrofunc = function(ob1, ob2, ob3: PPyObject): cint; cdecl;
  objobjargproc = function(obj1, obj2, obj3: PPyObject): cint; cdecl;
  traverseproc = function(ob1: PPyObject; proc: Pointer; ptr: Pointer): cint; cdecl;
  inquiry = function(ob1: PPyObject): cint; cdecl;
  richcmpfunc = function(ob1, ob2: PPyObject; i: cint): PPyObject; cdecl;
  getiterfunc = function(ob1: PPyObject): PPyObject; cdecl;
  iternextfunc = function(ob1: PPyObject): PPyObject; cdecl;
  descrgetfunc = function(ob1, ob2, ob3: PPyObject): PPyObject; cdecl;
  descrsetfunc = function(ob1, ob2, ob3: PPyObject): cint; cdecl;
  initproc = function(self, args, kwds: PPyObject): cint; cdecl;
  newfunc = function(subtype: PPyTypeObject; args, kwds: PPyObject): PPyObject; cdecl;
  allocfunc = function(self: PPyTypeObject; nitems: Py_ssize_t): PPyObject; cdecl;
  vectorcallfunc = function(callable: PPyObject; const args: PPPyObject;
    nargsf: size_t; kwnames: PPyObject): PPyObject; cdecl;
  getbufferproc = function(self: PPyObject; buffer: PPy_buffer; i: cint): cint; cdecl;
  releasebufferproc = procedure(self: PPyObject; buffer: PPy_buffer); cdecl;


  PPyMethodDef = ^PyMethodDef;
{
Описывает один метод в модуле или типе
}
  PyMethodDef  = record
    ml_name:  pansichar;   // Имя метода
    ml_meth:  PyCFunction; // Указатель на C-функцию
    ml_flags: cint;        // Флаги вызова (METH_VARARGS, METH_KEYWORDS и т.д
    ml_doc:   pansichar;   // Документация к методу или NULL
  end;

  PPyMemberDef = ^PyMemberDef;
{
Описывает один член (атрибут) типа
}
  PyMemberDef  = record
    Name:   pansichar;     // Имя члена
    _type:  cint;          // Тип данных (T_INT, T_STRING и т.д
    offset: Py_ssize_t;    // Смещение в структуре объекта
    flags:  cint;          // Флаги доступа (READONLY, READ_RESTRICTED)
    doc:    pansichar;     // Документация
  end;

  PPyGetSetDef = ^PyGetSetDef;
{
Описывает вычисляемый атрибут типа
}
  PyGetSetDef  = record
    Name:    pansichar; // Имя атрибута
    get:     getter;
    // Функция для получения значения (getter)
    _set:    setter;
    // Функция для установки значения (setter)
    doc:     pansichar;  // Документация
    closure: Pointer;    // Дополнительные данные для getter/setter
  end;

  Py_buffer = record
    buf:      Pointer;
    obj:      PPyObject;
    len:      Py_ssize_t;
    itemsize: Py_ssize_t;
    ReadOnly: cint;
    ndim:     cint;
    format:   pansichar;
    shape:    PPy_ssize_t;
    strides:  PPy_ssize_t;
    suboffsets: PPy_ssize_t;
    internal: Pointer;
  end;


  PPyBufferProcs = ^PyBufferProcs;

  PyBufferProcs = record
    bf_getbuffer:     getbufferproc;
    bf_releasebuffer: releasebufferproc;
  end;


  // ----------- Основные структуры объектов -----------
  PPyMutex = ^PyMutex;
{
Лёгкий мьютекс CPython, занимающий один байт.
Используется во внутренней реализации для синхронизации доступа к объектам
в режиме без GIL. Значение 0 соответствует разблокированному состоянию,
ненулевые значения — различным состояниям блокировки.
}
  PyMutex  = packed record
    _locked:  byte;  // uint8_t _locked;  // 0=unlocked, 1=locked
    {$IFDEF MSWINDOWS}// #if defined(_MSC_VER) — для выравнивания до sizeof(void*)
    _aligner: packed array[0..SizeOf(Pointer) - 2] of byte;
    // char _aligner[sizeof(void*)-1];
  {$ENDIF}
  end;
{
Базовая структура для всех объектов Python
Все объекты Python являются расширениями этой структуры. Она содержит
счетчик ссылок объекта и указатель на объект типа. В сборке без GIL (`Py_GIL_DISABLED`)
структура значительно усложнена для поддержки потокобезопасного подсчета ссылок.
}
  {$IFDEF Py_GIL_DISABLED}
  PyObject = packed record
    ob_tid:     uintptr_t;         // uintptr_t ob_tid;  // thread id or GC link
    ob_flags:   uint16_t;          // uint16_t ob_flags;
    ob_mutex:   PyMutex;           // PyMutex ob_mutex;  // per-object lock (1-8 байт+)
    ob_gc_bits: uint8_t;           //  ob_gc_bits;  // GC state
    ob_ref_local: uint32_t;        // uint32_t ob_ref_local;  // local refcount
    ob_ref_shared: Py_ssize_t;     // Py_ssize_t ob_ref_shared;  // shared refcount
    ob_type:    PPyTypeObject;     // PyTypeObject *ob_type;
  end;
  {$ELSE}
  {$IF SizeOf(Pointer) <= 4}// 32-bit: simple flat
  PyObject = packed record
    ob_refcnt: Py_ssize_t;       // 4 байта
    ob_type:   PPyTypeObject;    // 4 байта
  end;
  {$ELSE}
  PyObject = packed record
    {$IFDEF ENDIAN_BIG}  // Big-endian: flags, overflow, refcnt (для union struct)
      ob_flags: uint16_t;          // uint16_t ob_flags;
      ob_overflow: uint16_t;       // uint16_t ob_overflow;
      ob_refcnt: uint32_t;// uint32_t ob_refcnt;
    {$ELSE}  // Little-endian: refcnt, overflow, flags
      ob_refcnt: uint32_t;// uint32_t ob_refcnt;
      ob_overflow: uint16_t;       // uint16_t ob_overflow;
      ob_flags: uint16_t;          // uint16_t ob_flags;
    {$ENDIF}
    // Нет _aligner, т.к. на 64-bit он обычно 0 (выравнивание естественное)
    ob_type: PPyTypeObject;  // PyTypeObject *ob_type;  // 8 байт
  end;
  { Доступ к ob_refcnt_full: как PInt64(@obj.ob_refcnt_part)^ в little-endian
     (или adjust для big)
   Для big-endian: PInt64(@obj.ob_flags)^ — т.к. flags первые.
   Чтобы унифицировать -  function GetRefFull(const obj: PyObject): Int64;}
  {$ENDIF}
  {$ENDIF}


  PPyVarObject = ^PyVarObject;
{
Расширение PyObject для объектов переменного размера.
Содержит заголовок обычного объекта и поле ob_size с числом элементов
в «переменной» части (списки, кортежи и другие контейнеры).
}
  PyVarObject  = record
    ob_base: PyObject;
    ob_size: Py_ssize_t;
  end;

  PPyNumberMethods = ^PyNumberMethods;
{
Таблица числовых операций для типа.
Полям соответствуют реализации арифметических и логических операторов
(`+`, `-`, `*`, `//`, `%`, сдвиги, побитовые операции, матричное умножение
и их inplace-версии).
}
  PyNumberMethods  = record
    nb_add:   ternaryfunc;
    nb_subtract: ternaryfunc;
    nb_multiply: ternaryfunc;
    nb_remainder: ternaryfunc;
    nb_divmod: ternaryfunc;
    nb_power: ternaryfunc;
    nb_negative: reprfunc;
    nb_positive: reprfunc;
    nb_absolute: reprfunc;
    nb_bool:  inquiry;
    nb_invert: reprfunc;
    nb_lshift: ternaryfunc;
    nb_rshift: ternaryfunc;
    nb_and:   ternaryfunc;
    nb_xor:   ternaryfunc;
    nb_or:    ternaryfunc;
    nb_int:   reprfunc;
    nb_reserved: Pointer;
    nb_float: reprfunc;
    nb_inplace_add: ternaryfunc;
    nb_inplace_subtract: ternaryfunc;
    nb_inplace_multiply: ternaryfunc;
    nb_inplace_remainder: ternaryfunc;
    nb_inplace_power: ternaryfunc;
    nb_inplace_lshift: ternaryfunc;
    nb_inplace_rshift: ternaryfunc;
    nb_inplace_and: ternaryfunc;
    nb_inplace_xor: ternaryfunc;
    nb_inplace_or: ternaryfunc;
    nb_floor_divide: ternaryfunc;
    nb_true_divide: ternaryfunc;
    nb_inplace_floor_divide: ternaryfunc;
    nb_inplace_true_divide: ternaryfunc;
    nb_index: reprfunc;
    nb_matrix_multiply: ternaryfunc;
    nb_inplace_matrix_multiply: ternaryfunc;
  end;

  PPySequenceMethods = ^PySequenceMethods;
{
Таблица операций последовательности.
Определяет длину, конкатенацию, повторение, доступ по индексу,
присваивание элементу и принадлежность (`in`).
}
  PySequenceMethods  = record
    sq_length:    inquiry;
    sq_concat:    ternaryfunc;
    sq_repeat:    descrgetfunc;
    sq_item:      descrgetfunc;
    was_sq_slice: Pointer;
    sq_ass_item:  descrsetfunc;
    was_sq_ass_slice: Pointer;
    sq_contains:  inquiry;
    sq_inplace_concat: ternaryfunc;
    sq_inplace_repeat: descrgetfunc;
  end;

  PPyMappingMethods = ^PyMappingMethods;
{
Таблица операций отображения (словари и подобные объекты).
Содержит функции для получения длины, доступа по ключу и присваивания
значения по ключу.
}
  PyMappingMethods  = record
    mp_length:    inquiry;
    mp_subscript: ternaryfunc;
    mp_ass_subscript: objobjargproc;
  end;


{
Структура, определяющая новый тип Python.
Она содержит всю информацию, необходимую для описания поведения типа:
имя и размеры экземпляра, таблицы числовых/последовательностных/отображательных
методов, обработчики атрибутов, протоколы выделения памяти, наследования,
дескрипторов, сборщика мусора и т.п.
}
  PyTypeObject = record
    { Заголовок объекта переменного размера, наследуется от PyVarObject }
    ob_base:      PyVarObject;
    { Имя типа в формате "<module>.<name>" }
    tp_name:      pansichar;
    { Базовый размер экземпляра типа в байтах }
    tp_basicsize: Py_ssize_t;
    { Размер элемента для объектов переменного размера (например, `list`) }
    tp_itemsize:  Py_ssize_t;

    { Деструктор; вызывается при `ob_refcnt` = 0 }
    tp_dealloc:  pydestructor;
    { Смещение к функции vectorcall; `> 0` если протокол реализован }
    tp_vectorcall_offset: Py_ssize_t;
    { Устаревший getter атрибутов; используйте `tp_getattro` }
    tp_getattr:  getattrfunc;
    { Устаревший setter атрибутов; используйте `tp_setattro` }
    tp_setattr:  setattrfunc;
    { Указатель на структуру с асинхронными методами (`await`, `aiter`, `anext`) }
    tp_as_async: Pointer; // PPyAsyncMethods
    { Функция для `repr(obj)` }
    tp_repr:     reprfunc;

    { Указатель на структуру с числовыми методами }
    tp_as_number:   PPyNumberMethods;
    { Указатель на структуру с методами последовательности }
    tp_as_sequence: PPySequenceMethods;
    { Указатель на структуру с методами отображения }
    tp_as_mapping:  PPyMappingMethods;

    { Функция для `hash(obj)` }
    tp_hash:     hashfunc;
    { Функция для вызова объекта `obj(..` }
    tp_call:     ternaryfunc;
    { Функция для `str(obj)` }
    tp_str:      reprfunc;
    { Функция для получения атрибута `getattr(obj, name)` }
    tp_getattro: getattrofunc;
    { Функция для установки атрибута `setattr(obj, name, value)` }
    tp_setattro: setattrofunc;

    { Указатель на структуру с методами буферного протокола }
    tp_as_buffer: PPyBufferProcs;
    { Битовые флаги, определяющие поведение типа (см. `Py_TPFLAGS_*`) }
    tp_flags: culong;
    { Строка документации (`__doc__`) }
    tp_doc: pansichar;

    { Функция для обхода объекта сборщиком мусора }
    tp_traverse: traverseproc;
    { Функция для очистки внутренних ссылок сборщиком мусора }
    tp_clear:    inquiry;

    { Функция для "богатых" сравнений (`==`, `!=`, `<`, `>` и т.д }
    tp_richcompare:    richcmpfunc;
    { Смещение к списку слабых ссылок в экземпляре }
    tp_weaklistoffset: Py_ssize_t;

    { Функция для получения итератора `iter(obj)` }
    tp_iter:     getiterfunc;
    { Функция для получения следующего элемента итератора `next(iter)` }
    tp_iternext: iternextfunc;

    { Указатель на массив методов типа (`PyMethodDef`) }
    tp_methods:  PPyMethodDef;
    { Указатель на массив членов типа (`PyMemberDef`) }
    tp_members:  PPyMemberDef;
    { Указатель на массив вычисляемых атрибутов (`PyGetSetDef`) }
    tp_getset:   PPyGetSetDef;
    { Базовый тип, от которого наследуется данный тип }
    tp_base:     PPyTypeObject;
    { Словарь атрибутов типа (`__dict__`) }
    tp_dict:     PPyObject;
    { Функция-геттер для дескрипторов }
    tp_descr_get: descrgetfunc;
    { Функция-сеттер для дескрипторов }
    tp_descr_set: descrsetfunc;
    { Смещение к словарю экземпляра (`__dict__`) }
    tp_dictoffset: Py_ssize_t;
    { Функция-инициализатор экземпляра (`__init__`) }
    tp_init:     initproc;
    { Функция для выделения памяти под экземпляр }
    tp_alloc:    allocfunc;
    { Функция для создания экземпляра (`__new__`) }
    tp_new:      newfunc;
    { Низкоуровневая функция освобождения памяти (обычно `PyObject_GC_Del`) }
    tp_free:     pydestructor; // freefunc
    { Проверка, отслеживается ли объект сборщиком мусора }
    tp_is_gc:    inquiry;
    { Кортеж базовых типов (`__bases__`) }
    tp_bases:    PPyObject;
    { Порядок разрешения методов (`__mro__`) }
    tp_mro:      PPyObject;
    { Больше не используется }
    tp_cache:    Pointer;
    { Список подклассов (для статических типов это индекс) }
    tp_subclasses: Pointer;
    { Список слабых ссылок на сам объект типа }
    tp_weaklist: PPyObject;
    { Устаревший деструктор }
    tp_del:      pydestructor;

    { Тег версии кэша атрибутов типа. Увеличивается при изменении типа }
    tp_version_tag: cuint;
    { Финализатор объекта (`__del__`) }
    tp_finalize:    pydestructor;
    { Указатель на функцию vectorcall }
    tp_vectorcall:  vectorcallfunc;

    { Битовый набор, указывающий, какие наблюдатели отслеживают этот тип }
    tp_watched: cuchar;
    { Количество использованных значений `tp_version_tag` }
    tp_versions_used: cushort;
  end;


  PPy_Identifier = ^Py_Identifier;
{
Структура для управления статическими строками-идентификаторами.
Используется внутренними API для ленивого интернирования часто
встречающихся имён (атрибутов, методов и т.п.
}
  Py_Identifier  = record
    { Строковое представление идентификатора }
    str:   PChar;
    { Индекс в кэше интернированных строк. Инициализируется значением -1 }
    index: Py_ssize_t;
    { Внутренний мьютекс для потокобезопасности }
    mutex: record
      v: uint8_t;
      end;
  end;


const
  // Flag values for ob_flags
  _Py_IMMORTAL_FLAGS = 1 shl 0;
  _Py_STATICALLY_ALLOCATED_FLAG = 1 shl 2;

  {$IFDEF Py_GIL_DISABLED}
  _Py_IMMORTAL_REFCNT_LOCAL = High(uint32);
  {$ENDIF}

  {$IF SizeOf(Pointer) > 4}// 64-bit
  _Py_IMMORTAL_INITIAL_REFCNT = 3 shl 30;
  _Py_STATIC_FLAG_BITS = _Py_IMMORTAL_FLAGS or _Py_STATICALLY_ALLOCATED_FLAG;
  _Py_STATIC_IMMORTAL_INITIAL_REFCNT =
    CUInt64(_Py_IMMORTAL_INITIAL_REFCNT) or (CUInt64(_Py_STATIC_FLAG_BITS) shl 48);
  {$ELSE} // 32-bit
  _Py_STATIC_IMMORTAL_INITIAL_REFCNT = 7 shl 28;
  {$ENDIF}

  { Идентификаторы встроенных констант (см. object.h). }
  Py_CONSTANT_NONE     = 0;
  Py_CONSTANT_FALSE    = 1;
  Py_CONSTANT_TRUE     = 2;
  Py_CONSTANT_ELLIPSIS = 3;
  Py_CONSTANT_NOT_IMPLEMENTED = 4;
  Py_CONSTANT_ZERO     = 5;
  Py_CONSTANT_ONE      = 6;
  Py_CONSTANT_EMPTY_STR = 7;
  Py_CONSTANT_EMPTY_BYTES = 8;
  Py_CONSTANT_EMPTY_TUPLE = 9;


var
  {API - функции}

  { Возвращает строку с версией интерпретатора Python. }
  Py_GetVersion: function: pansichar; cdecl;

  { Возвращает флаги типа `tp_flags`. }
  PyType_GetFlags: function(tp: PPyTypeObject): culong;

  { Проверяет, является ли тип a подтипом типа b (включая сам тип). }
  PyType_IsSubtype: function(a, b: PPyTypeObject): cint; cdecl;

  { Блокирует/разблокирует объектный мьютекс }
  PyMutex_Lock: procedure(m: PPyMutex); cdecl;
  PyMutex_Unlock: procedure(m: PPyMutex); cdecl;
  {$IFNDEF PY_3.13}
  PyMutex_IsLocked: function(m: PPyMutex): cbool; cdecl;
  {$ENDIF}

  { Увеличивает/уменьшает счётчик ссылок объекта. }
  Py_IncRef: procedure(obj: PPyObject); cdecl;
  Py_DecRef: procedure(obj: PPyObject); cdecl;

  { Функции управления состоянием GIL. }
  PyGILState_Check: function: cint; cdecl;
  PyGILState_Ensure: function(): PyGILState_STATE; cdecl;
  PyGILState_Release: procedure(state: PyGILState_STATE); cdecl;

  { Инициализирует заголовок объекта указанным типом. Используется
    при создании статически размещённых объектов. }
  PyObject_Init: function(op: PPyObject; typeobj: PPyTypeObject): PPyObject; cdecl;

  { Проверка/управление атрибутами объекта. }
  PyObject_HasAttr: function(o: PPyObject; attr_name: PPyObject): cint; cdecl;
  PyObject_HasAttrString: function(o: PPyObject; const attr_name: pansichar): cint; cdecl;
  PyObject_DelAttr: function(o: PPyObject; attr_name: PPyObject): cint; cdecl;
  PyObject_DelAttrString: function(o: PPyObject; const attr_name: pansichar): cint; cdecl;
  PyObject_GetAttrString: function(o: PPyObject; const attr_name: pansichar): PPyObject; cdecl;
  PyObject_SetAttrString: function(ob: PPyObject; key: pansichar;
  Value: PPyObject): integer; cdecl;

  { Проверка, является ли объект значением None (аналог "x is None"). }
  Py_IsNone: function(x: PPyObject): cbool; cdecl;

  { Сбрасывает текущую ошибку в интерпретаторе (если установлена). }
  PyErr_Clear: procedure; cdecl;


  {$IFDEF  Py_LIMITED_API}
  { Доступ к таблице встроенных констант (None, True, False, и т.п. }
  Py_GetConstantBorrowed: function(constant_id: cuint): PPyObject; cdecl;
  Py_GetConstant: function(constant_id: cuint): PPyObject; cdecl;
  {$ENDIF}
  { Переменная Py_None, аналог макроса Py_None в CPython. Инициализируется
    в блоке initialization через _Py_NoneStruct или Py_GetConstantBorrowed. }
  Py_None: PPyObject;

  // Макросы API

{ Безопасно приводит произвольный указатель к PPyObject. }
function _PyObject_CAST(ob: Pointer): PPyObject; inline;
{ Возвращает указатель на тип объекта `o`. }
function Py_TYPE(o: PPyObject): PPyTypeObject; inline;
{ Проверяет, установлен ли у типа `o` указанный флаг `feature`. }
function PyType_HasFeature(o: PPyTypeObject; feature: culong): cbool; inline;
{ Быстрая проверка, является ли тип `o` подклассом с флагом `feature`. }
function PyType_FastSubclass(o: PPyTypeObject; feature: culong): cbool; inline;
{ Проверяет, является ли тип объекта `ob` в точности `type`. }
function Py_IS_TYPE(ob: PPyObject; tp: PPyTypeObject): cbool; inline;
{ Проверяет, что тип объекта `obj` совпадает с `t` или является его подтипом. }
function PyObject_TypeCheck(obj: PPyObject; t: PPyTypeObject): cbool; inline;
{ Аналог макроса Py_XDECREF: уменьшает счётчик ссылок, если указатель не nil. }
procedure Py_XDECREF(op: PPyObject); inline;
{Инициализирует ob_base любого PyObject-подобного объекта }
procedure PyObject_HEAD_INIT(obj: Pointer; ObType: PPyTypeObject); inline;


// Паскаль-хелперы модуля ------------------

{$IFNDEF Py_GIL_DISABLED}
{ Возвращает полный 64-битный счётчик ссылок для объекта в сборке с GIL. }
function GetRefFull(const obj: PyObject): uint64_t; inline;
{$ENDIF}
 { Загружает динамическую библиотеку Python и подготавливает var-функции
   для последующего вызова через GetProc.}
procedure InitPythonAPI; noinline;
 { Возвращает адрес функции/процедуры из загруженной библиотеки Python
   по её C-имени. При ошибке возвращает nil. }
function GetProc(const Name: pansichar): Pointer; noinline;


procedure writeOk; noinline;
procedure writeError; noinline;
procedure writeDot; noinline;
procedure writeDel; noinline;
procedure writeBox; noinline;

implementation

uses  DynLibs
  {$IFDEF Py_GIL_DISABLED}
 ,py_atomic_ext
  {$ENDIF}
  ;

const

  {хандл файла питон-библиотиеки}
  PythonLib: TLibHandle     = Default(TLibHandle);
  {Ссылка на объект, который в Python отображается как None.
   Доступ к нему следует осуществлять только с помощью функции Py_None,
   которая возвращает указатель на этот объект.}
  _Py_NoneStruct: PPyObject = Default(PPyObject);


procedure PyObject_HEAD_INIT(obj: Pointer; ObType: PPyTypeObject); inline;
var
  pyObj: PPyObject;
begin
  pyObj := PPyObject(obj);
  {$IFDEF Py_GIL_DISABLED}
  with pyObj^ do
  begin
    // Initialize based on the Py_GIL_DISABLED PyObject structure
    ob_tid     := 0;
    ob_flags   := _Py_STATICALLY_ALLOCATED_FLAG;
    ob_mutex   := Default(PyMutex);
    ob_gc_bits := 0;
    ob_ref_local := _Py_IMMORTAL_REFCNT_LOCAL;
    ob_ref_shared := 0;
    ob_type    := ObType;
  end;
  {$ELSE}
  {$IF SizeOf(Pointer) <= 4}// 32-bit without GIL
  // Initialize simple flat 32-bit structure
  pyObj^.ob_refcnt := _Py_STATIC_IMMORTAL_INITIAL_REFCNT;
  pyObj^.ob_type := ObType;
  {$ELSE}
 // 64-bit without GIL
    // In 64-bit, the record uses a union-like structure. We initialize the full
    // 64-bit value by casting the address of the first field in the structure
    // to a 64-bit integer pointer.
    {$IFDEF ENDIAN_BIG}
    PInt64(@pyObj^.ob_flags)^ := _Py_STATIC_IMMORTAL_INITIAL_REFCNT;
    {$ELSE}
    PInt64(@pyObj^.ob_refcnt)^ := _Py_STATIC_IMMORTAL_INITIAL_REFCNT;
    {$ENDIF}
    pyObj^.ob_type := ObType;
  {$ENDIF}
  {$ENDIF}
end;


function PythonDLLEmbedded(const PythonFullPath: ansistring; index: integer): ansistring;
  noinline;
var
  i, last: integer;
begin
  Result := '';
  last   := 0;
  for i := Length(PythonFullPath) downto 1 do
    {$IFDEF MSWINDOWS}
    if PythonFullPath[i] = '\' then
  {$ELSE}
  if PythonFullPath[i] = '/' then
  {$ENDIF}
    begin
      last := i;
      Break;
    end;
  Result := Copy(PythonFullPath, 1, last) + PythonFullNameAr[index];
end;


function GetProc(const Name: pansichar): Pointer; noinline;
begin
  Result := GetProcedureAddress(PythonLib, Name);
  {$IFDEF DEBUG}
  if Assigned(Result) then
  writeOk
  else writeError;
  writeln(Name);
  exit;
  {$ENDIF}
  {$IFDEF PY_CONSOLE}
  if not assigned(Result) then writeln('✗ ', Name);
  {$ENDIF}
end;

{$IFNDEF Py_GIL_DISABLED}
function GetRefFull(const obj: PyObject): uint64_t; inline;
begin
  {$IFDEF ENDIAN_BIG}
  Result := PUInt64(@obj.ob_flags)^;
  {$ELSE}
  // В little-endian поле ob_refcnt и соседние биты образуют полный 64-битный счётчик
  Result := PUInt64(@obj.ob_refcnt)^;
  {$ENDIF}
end;
{$ENDIF}


function _PyObject_CAST(ob: Pointer): PPyObject; inline;
begin
  Result := PPyObject(ob);
end;

function Py_TYPE(o: PPyObject): PPyTypeObject; inline;
begin
  {$IFDEF Py_LIMITED_API}
  // В ограниченном API PyTypeObject может быть не полностью видим,
  // но указатель на тип всё равно хранится в заголовке объекта.
  if (o = nil) then
    Result := nil
  else
    Result := _PyObject_CAST(o)^.ob_type;
  {$ELSE}
  if assigned(o) then
    Result := nil
  else
    Result := _PyObject_CAST(o)^.ob_type;
  {$ENDIF}
end;

function PyType_HasFeature(o: PPyTypeObject; feature: culong): cbool; inline;
begin
  {$IFDEF Py_LIMITED_API}
  // PyTypeObject не виден в ограниченном API
  Result := (PyType_GetFlags(o) and feature) <> 0;
  {$ELSE}
  Result := (o^.tp_flags and feature) <> 0;
  {$ENDIF}
end;

function PyType_FastSubclass(o: PPyTypeObject; feature: culong): cbool; inline;
begin
  Result := PyType_HasFeature(o, feature);
end;

function Py_IS_TYPE(ob: PPyObject; tp: PPyTypeObject): cbool; inline;
begin
  Result := Py_TYPE(ob) = tp;
end;

function PyObject_TypeCheck(obj: PPyObject; t: PPyTypeObject): cbool; inline;
begin
  Result := Py_IS_TYPE(obj, t) or (PyType_IsSubtype(obj^.ob_type, t) = 1);
end;


procedure InitPythonAPI; noinline;
var
  i: integer;
begin
  {$IFDEF Py_PORTABLE}
  for i := low(PythonFullNameAr) to high(PythonFullNameAr) do
  begin
    PythonLib := LoadLibrary(PythonDLLEmbedded(ParamStr(0), i));
    if PythonLib <> NilHandle then exit;
  end;
  {$IFDEF DEBUG}
  writeError;
  Writeln(PythonFullNameAr[i]);
  {$ENDIF}
  {$ENDIF}
  for i := low(PythonFullNameAr) to High(PythonFullNameAr) do
  begin
    PythonLib := LoadLibrary(PythonFullNameAr[i]);
    if PythonLib <> NilHandle then exit;
    {$IFDEF DEBUG}
    writeError;
    Writeln(PythonFullNameAr[i]);
    {$ENDIF}
  end;
end;

procedure writeOk;
begin
  Write('✓ ');
end;

procedure writeError; noinline;
begin
  Write('✗ ');
end;


procedure writeDot; noinline;
begin
  Write('.');
end;

procedure writeDel;
begin
  Write(#$E2#$8C#$AB, ' ');
end;

procedure writeBox; noinline;
begin
  Write('📦 ');
end;

function IsLoadedLib: boolean;
begin
  Result := PythonLib <> NilHandle;
end;

procedure Py_XDECREF(op: PPyObject); inline;
begin
  if assigned(op) then
    Py_DecRef(op);
end;

function Py_IsNoneObj(obj: PPyObject): cbool; inline;
begin
  Result := assigned(Py_IsNone) and (Py_IsNone(obj));
end;


initialization
  InitPythonAPI;
  Pointer(Py_GetVersion) := GetProc('Py_GetVersion');
  {$IFDEF Debug}
  writeln('Версия компилятора: ', {$I %FPCVERSION%});
  writeln('Дата компиляции: ', {$I %DATE%});
  writeln('Python: ',Py_GetVersion);
  {$ENDIF}

  { Базовые функции и типовая информация }
  Pointer(PyObject_Init)    := GetProc('PyObject_Init');
  Pointer(PyType_GetFlags)  := GetProc('PyType_GetFlags');
  Pointer(PyType_IsSubtype) := GetProc('PyType_IsSubtype');

  { Мьютексы (No-GIL/low-level sync) }
  Pointer(PyMutex_Lock)   := GetProc('PyMutex_Lock');
  Pointer(PyMutex_Unlock) := GetProc('PyMutex_Unlock');
  {$IFNDEF PY_3.13}
  Pointer(PyMutex_IsLocked) := GetProc('PyMutex_IsLocked');
  {$ENDIF}

  { Подсчёт ссылок }
  Pointer(Py_IncRef) := GetProc('Py_IncRef');
  Pointer(Py_DecRef) := GetProc('Py_DecRef');

  { Атрибуты объектов }
  Pointer(PyObject_HasAttr) := GetProc('PyObject_HasAttr');
  Pointer(PyObject_HasAttrString) := GetProc('PyObject_HasAttrString');
  Pointer(PyObject_DelAttr) := GetProc('PyObject_DelAttr');
  Pointer(PyObject_DelAttrString) := GetProc('PyObject_DelAttrString');
  Pointer(PyObject_GetAttrString) := GetProc('PyObject_GetAttrString');
  Pointer(PyObject_SetAttrString) := GetProc('PyObject_SetAttrString');

  Pointer(Py_IsNone) := GetProc('Py_IsNone');
  _Py_NoneStruct     := GetProc('_Py_NoneStruct');

  {$IFDEF Py_LIMITED_API}
  Pointer(Py_GetConstantBorrowed) := GetProc('Py_GetConstantBorrowed');
  Pointer(Py_GetConstant) := GetProc('Py_GetConstant');
  Py_None := Py_GetConstantBorrowed(Py_CONSTANT_NONE);
  {$ELSE}
  Py_None := _Py_NoneStruct;
  {$ENDIF}

  { GIL API и ошибки }
  Pointer(PyGILState_Check) := GetProc('PyGILState_Check');
  Pointer(PyGILState_Ensure) := GetProc('PyGILState_Ensure');
  Pointer(PyGILState_Release) := GetProc('PyGILState_Release');
  Pointer(PyErr_Clear) := GetProc('PyErr_Clear');

  {$IFDEF Py_GIL_DISABLED}
  // py_atomic_ext.Init;
  {$ENDIF}


finalization
  // При выгрузке модуля освобождаем библиотеку Python
  if PythonLib <> NilHandle then
  begin
    FreeLibrary(PythonLib);
    PythonLib := 0;
  end;
end.
