{
  Этот модуль содержит о функции для создания модулей на FPC,
   которые можно импортировать в Python.
  Целевая версия Python: 3.14
  Ограниченный функционал 3.13 поддерживается через условную компиляцию Python313
  No_GIL версия поддерживается через условную компиляцию Py_GIL_DISABLED
  Только базовый функционал поддерживается через условную компиляцию Py_LIMITED_API
  "Устаревший" на момент 3.14 функционал не поддерживается
  }
{$mode fpc}
{$i config.inc}
unit py_modsupport;

interface

uses
  ctypes, python;

const


  // --- КОНСТАНТЫ ДЛЯ СЛОТОВ ---
  // Стандартные слоты
  Py_mod_create = 1;
  Py_mod_exec   = 2;
  Py_mod_multiple_interpreters = 3;
  // Слот для поддержки нескольких интерпретаторов
  {$IFDEF Py_GIL_DISABLED}
  // Слот для No-GIL сборок (Python 3.13+)
  // Этот флаг должен быть определен при компиляции вашего модуля
  Py_mod_gil = 4;
  // Значения для слота Py_mod_gil
  Py_MOD_GIL_USED = Pointer(0);
  Py_MOD_GIL_NOT_USED = Pointer(1);
  {$ENDIF}

  {$IFNDEF PY_LIMITED_API}
  //---------------------------------------------------------------------
  // Флаги ABI-информации (PyABIInfo.flags)
  //---------------------------------------------------------------------
  PyABIInfo_STABLE   = $0001;
  PyABIInfo_GIL      = $0002;
  PyABIInfo_FREETHREADED = $0004;
  PyABIInfo_INTERNAL = $0008;
  {$ENDIF}

type
  //---------------------------------------------------------------------
  // Структуры API
  //---------------------------------------------------------------------
{
@abstract(Базовая структура для определения модуля.)
}
  PPyModuleDef_Base = ^PyModuleDef_Base;

  PyModuleDef_Base = record
    ob_base: PyObject;
    m_init:  function(): PPyObject; cdecl;
    m_index: Py_ssize_t;
    m_copy:  PPyObject;
  end;
  PPyModuleDef_Slot = ^PyModuleDef_Slot;
{
(Определяет слот в определении модуля PyModuleDef.)
(Используется для расширенной инициализации модуля.)
}
  PyModuleDef_Slot  = record
    slot:  cint; //Идентификатор слота.
    Value: Pointer;
    //Значение слота, зависящее от идентификатора.
  end;
  PPyModuleDef = ^PyModuleDef;
{
(Определяет структуру модуля Python.)
}
  PyModuleDef  = record
    m_base:     PyModuleDef_Base;
    m_name:     pansichar;
    m_doc:      pansichar;
    m_size:     Py_ssize_t;
    m_methods:  PPyMethodDef;
    m_slots:    PPyModuleDef_Slot;
    m_traverse: traverseproc;
    m_clear:    inquiry;
    m_free:     pydestructor;
  end;

  {$IFNDEF PY_LIMITED_API}
  PyABIInfo = record
    abiinfo_major_version: cuint8;
    abiinfo_minor_version: cuint8;
    flags: cuint16;
    build_version: cuint32;
    abi_version: cuint32;
  end;
  PPyABIInfo = ^PyABIInfo;
  {$ENDIF}

var
  //---------------------------------------------------------------------
  // Переменные API
  //---------------------------------------------------------------------

  { Тип объекта модуля PyModuleDef_Type (используется при создании модулей). }
  PyModuleDef_Type: PPyTypeObject;

  {$IFNDEF PY_LIMITED_API}
  { Проверка ABI-информации модуля на совместимость с текущим интерпретатором. }
  PyABIInfo_Check: function(info: PPyABIInfo; module_name: pansichar): cint; cdecl;
  {$ENDIF}


  //---------------------------------------------------------------------
  // функции API
  //---------------------------------------------------------------------
  { PyModuleDef_Init(def) -> PyModuleDef*
    Подготавливает структуру определения модуля перед созданием объекта модуля. }
  PyModuleDef_Init: function(Module: PPyModuleDef): PPyModuleDef; cdecl;

  { PyModule_Create2(def, apiver) -> PyObject*
    Создаёт новый объект модуля на основе PyModuleDef и версии API. }
  PyModule_Create2: function(Module: PPyModuleDef; module_api_version: cint): PPyObject; cdecl;


  { PyModule_AddObject(mod, name, value) -> int
    Добавляет атрибут name со значением value в модуль mod. Похожа на
    PyModule_AddObjectRef/PyModule_Add, но ворует ссылку только при успехе.
    Возвращает 0 при успехе, -1 при ошибке. }
  PyModule_AddObject: function(Module: PPyObject; Name: pansichar; Value: PPyObject): cint; cdecl;

  { PyModule_AddIntConstant(mod, name, value) -> int
    Добавляет в модуль целочисленную константу name = value. Возвращает 0 при
    успехе и -1 при ошибке. }
  PyModule_AddIntConstant: function(Module: PPyObject; Name: pansichar;
  AValue: clong): cint; cdecl;

  { PyModule_AddStringConstant(mod, name, value) -> int
    Добавляет в модуль строковую константу name = value (копируя строку).
    Возвращает 0 при успехе и -1 при ошибке. }
  PyModule_AddStringConstant: function(Module: PPyObject; Name, Value: pansichar): cint; cdecl;

  // В полном API доступны дополнительные функции модульной поддержки.
  // PyCFunction_NewEx объявляем всегда, так как она используется и в pascal-like
  // обёртках, а наличие самой функции определяется на этапе привязки через GetProc.
  PyCFunction_NewEx: function(ml: PPyMethodDef; Self: PPyObject;
  Module: PPyObject): PPyObject; cdecl;

  {$IFNDEF PY_LIMITED_API}
  PyModule_AddFunctions: function(Obj: PPyObject; MethodDef: PPyMethodDef): cint; cdecl;
  PyCMethod_New: function(ml: PPyMethodDef; Self: PPyObject; Module: PPyObject;
  cls: PPyTypeObject): PPyObject; cdecl;
  PyModule_New: function(key: pansichar): PPyObject; cdecl;
  PyModule_FromDefAndSpec2: function(def: PPyModuleDef; spec: PPyObject;
  module_api_version: cint): PPyObject; cdecl;
  PyModule_ExecDef: function(Module: PPyObject; moduledef: PPyModuleDef): cint; cdecl;

  { PyModule_AddObjectRef(mod, name, value) -> int
    Добавляет атрибут name со значением value в модуль mod, не изменяя счётчик
    ссылок value. Возвращает 0 при успехе, -1 при ошибке. }
  PyModule_AddObjectRef: function(Module: PPyObject; const Name: pansichar;
  Value: PPyObject): cint; cdecl;

  { PyModule_Add(mod, name, value) -> int
    Как PyModule_AddObjectRef(), но ворует ссылку на value: при успехе вызывать
    Py_DECREF(value) не нужно. Новая функция полного API (3.13+). }
  PyModule_Add: function(Module: PPyObject; Name: pansichar; Value: PPyObject): cint; cdecl;

  { PyModule_SetDocString(mod, doc) -> int
    Устанавливает строку документации модуля. Возвращает 0 при успехе, -1 при
    ошибке. Новое в 3.5, только полный API. }
  PyModule_SetDocString: function(Module: PPyObject; doc: pansichar): cint; cdecl;

  { PyModule_AddType(mod, type_) -> int
    Добавляет тип type_ в модуль mod и при необходимости устанавливает
    корректное значение __module__. Новое в 3.9, только полный API. }
  PyModule_AddType: function(Module: PPyObject; type_: PPyTypeObject): cint; cdecl;
  {$ENDIF}

  { PyModule_GetDef(Module) -> PyModuleDef*
    Возвращает внутреннюю структуру определения модуля для объекта Module. }
  PyModule_GetDef: function(Module: PPyObject): PPyModuleDef; cdecl;

  { PyModule_GetNameObject(Module) -> PyObject*
    Возвращает имя модуля в виде объекта str. Возвращает new reference или nil
    при ошибке. }
  PyModule_GetNameObject: function(Module: PPyObject): PPyObject; cdecl;

  { PyImport_ImportModule(name) -> PyObject*
    Импортирует модуль по имени name и возвращает new reference на объект модуля
    или nil при ошибке (ImportError и др.). }
  PyImport_ImportModule: function(Name: pansichar): PPyObject; cdecl;

  { PyArg_Parse(args, format, ...) -> int
    Разбирает позиционные аргументы args по C-формату format в набор C-переменных.
    Возвращает 1 при успехе и 0 при ошибке, устанавливая соответствующее исключение. }
  PyArg_Parse: function(args: PPyObject; format: pansichar): cint; cdecl; varargs;

  { PyArg_ParseTuple(args, format, ...) -> int
    Вариант PyArg_Parse для кортежа аргументов. Возвращает 1 при успехе, 0 при ошибке. }
  PyArg_ParseTuple: function(args: PPyObject; format: pansichar): cint; cdecl; varargs;

  { PyArg_ParseTupleAndKeywords(args, kwargs, format, keywords, ...) -> int
    Разбирает позиционные и именованные аргументы по формату format и таблице keywords.
    Возвращает 1 при успехе, 0 при ошибке (обычно TypeError/ValueError). }
  PyArg_ParseTupleAndKeywords: function(args, kwargs: PPyObject; format: pansichar;
  keywords: PPAnsiChar): cint; cdecl; varargs;

  { PyArg_VaParse(args, format, va) -> int
    Вариант PyArg_Parse, работающий с уже подготовленным va_list. }
  PyArg_VaParse: function(args: PPyObject; format: pansichar; va: Pointer): cint; cdecl;

  { PyArg_VaParseTupleAndKeywords(args, kwargs, format, keywords, va) -> int
    Вариант PyArg_ParseTupleAndKeywords для va_list. }
  PyArg_VaParseTupleAndKeywords: function(args, kwargs: PPyObject; format: pansichar;
  keywords: PPAnsiChar; va: Pointer): cint; cdecl;

  { PyArg_ValidateKeywordArguments(kwargs) -> int
    Проверяет, что kwargs содержит только разрешённые ключи. Возвращает 1 при
    успехе, 0 при ошибке (обычно TypeError). }
  PyArg_ValidateKeywordArguments: function(kwargs: PPyObject): cint; cdecl;

  { PyArg_UnpackTuple(args, name, min, max, ...) -> int
    Распаковывает кортеж args в заданное число C-переменных (от min до max).
    Возвращает 1 при успехе, 0 при ошибке с установленным исключением. }
  PyArg_UnpackTuple: function(args: PPyObject; Name: pansichar; min, max: Py_ssize_t): cint;
  cdecl; varargs;

  { Py_BuildValue(format, ...) -> PyObject*
    Создаёт объект/кортеж Python по C-формату format. Возвращает new reference
    или nil при ошибке (MemoryError, TypeError и т.п.). }
  Py_BuildValue: function(format: pansichar): PPyObject; cdecl; varargs;

  { Py_VaBuildValue(format, va) -> PyObject*
    Вариант Py_BuildValue для уже подготовленного va_list. }
  Py_VaBuildValue: function(format: pansichar; va: Pointer): PPyObject; cdecl;


 //---------------------------------------------------------------------
 // Дополнительные функции библиотеки
 //---------------------------------------------------------------------
  { Инициализирует заголовок PyModuleDef по аналогии с макросом PyModuleDef_HEAD_INIT.
    Безопасно ничего не делает, если тип PyModuleDef_Type не привязан. }
procedure PyModuleDef_HEAD_INIT(var def: PyModuleDef); inline;

  { Init(ModuleDef, NameModule, VarSizeModule, DocModule) -> PyObject*
    Заполняет структуру PyModuleDef (имя, размер, документация) и создаёт модуль
    через PyModuleDef_Init и PyModule_Create2(…, PYTHON_API_VERSION).
    Возвращает new reference или nil при ошибке (включая отсутствие биндингов). }
function Init(var Module: PyModuleDef; const NameModule: pansichar;
  constref VarSizeModule: Py_ssize_t = 0; DocModule: pansichar = ''): PPyObject;

  { Add(Module, MethodDef, NameFunction) -> bool
    Создаёт объект функции на основе MethodDef и добавляет его в модуль Module
    под именем NameFunction (или ml_name, если NameFunction = nil).
    Возвращает True при успехе и False при ошибке или отсутствии нужных биндингов. }
function Add(var Module: PPyObject; const MethodDef: PPyMethodDef;
  const NameFunction: pansichar = nil): boolean;

  { Init(ModuleDef, Fun, NameModule, …) -> PyObject*
    Перегрузка Init: после создания модуля регистрирует все функции из массива
    Fun (nil-элементы пропускаются). Возвращает nil при ошибке создания модуля. }
function Init(var Module: PyModuleDef; constref Fun: array of PPyMethodDef;
  const NameModule: pansichar; constref VarSizeModule: Py_ssize_t = 0;
  DocModule: pansichar = ''): PPyObject;

  { Remove(Module, NameFunction) -> bool
    Удаляет атрибут NameFunction из модуля Module. При успехе возвращает True.
    При ошибке очищает текущее исключение PyErr и возвращает False. }
function Remove(var Module: PPyObject; const NameFunction: pansichar): boolean;

  { Replace(Module, NameFunction, MethodDef, NewFunction) -> bool
    Удаляет существующую функцию NameFunction и добавляет на её место новую,
    описанную MethodDef (имя можно переопределить через NewFunction).
    Успех только если обе операции (Remove и Add) прошли без ошибок. }
function Replace(var Module: PPyObject; const NameFunction: pansichar;
  const MethodDef: PPyMethodDef; const NewFunction: pansichar = nil): boolean;

  { GetModule(NameModule) -> PyObject*
    Обёртка над PyImport_ImportModule: импортирует модуль по имени NameModule и
    возвращает new reference или nil при ошибке/отсутствии биндинга. }
function GetModule(const NameModule: pansichar): PPyObject; inline;

  { Close(Module)
    Уменьшает счётчик ссылок модуля (Py_DECREF) и обнуляет переменную. Безопасна
    для nil. }
procedure Close(var Module: PPyObject); inline;

  { PyModule_AddIntMacro(Module, C, Name) -> int
    Удобная обёртка над PyModule_AddIntConstant: добавляет в модуль целочисленную
    константу с указанным именем Name и значением C. }
function PyModule_AddIntMacro(Module: PPyObject; const C: clong;
  const Name: pansichar): cint; inline;

  { PyModule_AddStringMacro(Module, Value, Name) -> int
    Обёртка над PyModule_AddStringConstant: добавляет строковую константу Name
    со значением Value. }
function PyModule_AddStringMacro(Module: PPyObject; const Value, Name: pansichar): cint; inline;

implementation

procedure PyModuleDef_HEAD_INIT(var def: PyModuleDef); inline;
begin
  if not Assigned(PyModuleDef_Type) then
    Exit;
  PyObject_HEAD_INIT(@def.m_base, PyModuleDef_Type);
  def.m_base.m_init  := nil;    // NULL для статической инициализации
  def.m_base.m_index := 0;      // 0 для статической инициализации
  def.m_base.m_copy  := nil;    // NULL для статической инициализации
end;

function GetNameFunction(Name: pansichar; Func: PPyMethodDef): pansichar; inline;
begin
  if Assigned(Name) then Result := Name
  else
    Result := Func^.ml_name;
end;

procedure WriteNameFunction(OkFlag: boolean; const PyModule: PPyObject;
  const NameFunction: pansichar);
begin
  if OkFlag then  writeOk
  else
    WriteError;
  Write(PyModule_GetDef(PyModule)^.m_name);
  WriteDot;
  Write(NameFunction);
  writeln;
end;

procedure WriteModule(OkFlag: boolean; const NameModule: pansichar);
begin
  if OkFlag then  writeOk
  else
    WriteError;
  WriteBox;
  Write(NameModule);
  writeln;
end;

function Init(var Module: PyModuleDef; const NameModule: pansichar;
  constref VarSizeModule: Py_ssize_t = 0; DocModule: pansichar = ''): PPyObject;
begin
  if (not Assigned(PyModuleDef_Init)) or (not Assigned(PyModule_Create2)) then
  begin
    Result := nil;
    Exit;
  end;
  PyModuleDef_HEAD_INIT(Module);
  with Module do
  begin
    m_name := NameModule;
    m_size := VarSizeModule;
    m_doc  := DocModule;
  end;
  Result := PyModule_Create2(PyModuleDef_Init(@Module), PYTHON_API_VERSION);
  if Assigned(Result) then
  begin
    {$IFDEF DEBUG}
    WriteModule(True, NameModule);
    {$ENDIF}
  end
  else
  begin
    PyErr_Clear;
    {$IF defined(PY_CONSOLE) or defined(DEBUG)}
    WriteModule(False, NameModule);
    {$ENDIF}
  end;
end;

function Add(var Module: PPyObject; const MethodDef: PPyMethodDef;
  const NameFunction: pansichar = nil): boolean;
var
  P: PPyObject;
begin
  Result := False; // значение по умолчанию

  if (Module = nil) or (MethodDef = nil) then
    Exit;

  {$IFNDEF PY_LIMITED_API}
  if Assigned(PyCMethod_New) and Assigned(PyModule_AddObjectRef) then
  begin
    P := PyCMethod_New(MethodDef, nil, Module, nil); // новая ссылка или nil
    if not Assigned(P) then
    begin
      // PyCMethod_New вернула nil, очищаем возможную ошибку
      PyErr_Clear();
      {$IF defined(PY_CONSOLE) or defined(DEBUG)}
      WriteNameFunction(False, Module, MethodDef^.ml_name);
      {$ENDIF}
      Exit; // Result остаётся False
    end;

    if PyModule_AddObjectRef(Module, GetNameFunction(NameFunction, MethodDef), P) < 0 then
    begin
      // PyModule_AddObjectRef не приняла владение P
      Py_XDECREF(P);
      {$IF defined(PY_CONSOLE) or defined(DEBUG)}
      WriteNameFunction(False, Module, GetNameFunction(NameFunction, MethodDef));
      {$ENDIF}
      PyErr_Clear;
      Exit;
    end;

    // Успех: владение P передано в модуль
    {$IFDEF DEBUG}
    WriteNameFunction(True, Module, GetNameFunction(NameFunction, MethodDef));
    {$ENDIF}
    Result := True;
  end;

  {$ELSE}
  // --- Limited API (или откат при отсутствии полного набора функций) ---
  if Assigned(PyCFunction_NewEx) and Assigned(PyModule_AddObject) then
  begin
    P := PyCFunction_NewEx(MethodDef, nil, nil); // новая ссылка или nil
    if not Assigned(P) then
    begin
      PyErr_Clear();
      {$IF defined(PY_CONSOLE) or defined(DEBUG)}
      WriteNameFunction(False, Module, MethodDef^.ml_name);
      {$ENDIF}
      Exit;
    end;

    if PyModule_AddObject(Module, GetNameFunction(NameFunction, MethodDef), P) < 0 then
    begin
      // PyModule_AddObject не принял владение P
      Py_DECREF(P);
      {$IF defined(PY_CONSOLE) or defined(DEBUG)}
      WriteNameFunction(False, Module, GetNameFunction(NameFunction, MethodDef));
      {$ENDIF}
      PyErr_Clear; // очищаем ошибку от PyModule_AddObject
      Exit;
    end;

    // Успех: владение P передано в модуль
    {$IFDEF DEBUG}
    WriteNameFunction(True, Module, GetNameFunction(NameFunction, MethodDef));
    {$ENDIF}
    Result := True;
    Exit;
  end;

  {$IF defined(PY_CONSOLE) or defined(DEBUG)}
  WriteNameFunction(False, Module, MethodDef^.ml_name);
  {$ENDIF}
  {$ENDIF}
end;

function Init(var Module: PyModuleDef; constref Fun: array of PPyMethodDef;
  const NameModule: pansichar; constref VarSizeModule: Py_ssize_t = 0;
  DocModule: pansichar = ''): PPyObject;
var
  i: integer;
begin
  Result := Init(Module, NameModule, VarSizeModule, DocModule);
  if Assigned(Result) then
    for i := 0 to Length(Fun) - 1 do
      if Assigned(Fun[i]) then
        Add(Result, Fun[i], Fun[i]^.ml_name);
end;


function Remove(var Module: PPyObject; const NameFunction: pansichar): boolean;
begin
  if (Module = nil) or (NameFunction = nil) then
  begin
    Result := False;
    Exit;
  end;
  Result := (PyObject_HasAttrString(Module, NameFunction) <> 0) and
    (PyObject_DelAttrString(Module, NameFunction) = 0);
  if Result then
  begin
    {$IF defined(PY_CONSOLE) or defined(DEBUG)}
    writeDel;
    WriteNameFunction(True, Module, NameFunction);
    {$ENDIF}
  end
  else
  begin
    PyErr_Clear();
    {$IFDEF DEBUG}
    writeDel;
    WriteNameFunction(False, Module, NameFunction);
    {$ENDIF}
  end;
end;

function Replace(var Module: PPyObject; const NameFunction: pansichar;
  const MethodDef: PPyMethodDef; const NewFunction: pansichar = nil): boolean; inline;
begin
  Result := Remove(Module, NameFunction) and Add(Module, MethodDef, NewFunction);
end;

function GetModule(const NameModule: pansichar): PPyObject; inline;
begin
  if (NameModule = nil) or (not Assigned(PyImport_ImportModule)) then
  begin
    Result := nil;
    Exit;
  end;
  Result := PyImport_ImportModule(NameModule);
  if Assigned(Result) then
  begin
    {$IFDEF DEBUG}
    WriteModule(True, NameModule);
    {$ENDIF}
  end
  else
  begin
    PyErr_Clear;
    {$IF defined(PY_CONSOLE) or defined(DEBUG)}
    WriteModule(False, NameModule);
    {$ENDIF}
  end;
end;


procedure Close(var Module: PPyObject); inline;
begin
  if Module <> nil then
  begin
    Py_DECREF(Module);
    Module := nil;
  end;
end;

function PyModule_AddIntMacro(Module: PPyObject; const C: clong;
  const Name: pansichar): cint; inline;
begin
  Result := PyModule_AddIntConstant(Module, Name, C);
end;

function PyModule_AddStringMacro(Module: PPyObject; const Value, Name: pansichar): cint; inline;
begin
  Result := PyModule_AddStringConstant(Module, Name, Value);
end;

initialization

  Pointer(PyModuleDef_Init) := GetProc('PyModuleDef_Init');
  Pointer(PyModule_Create2) := GetProc('PyModule_Create2');
  Pointer(PyArg_Parse)      := GetProc('PyArg_Parse');
  Pointer(PyArg_ParseTuple) := GetProc('PyArg_ParseTuple');
  Pointer(PyArg_ParseTupleAndKeywords) := GetProc('PyArg_ParseTupleAndKeywords');
  Pointer(PyArg_VaParse)    := GetProc('PyArg_VaParse');
  Pointer(PyArg_VaParseTupleAndKeywords) := GetProc('PyArg_VaParseTupleAndKeywords');
  Pointer(PyArg_ValidateKeywordArguments) := GetProc('PyArg_ValidateKeywordArguments');
  Pointer(PyArg_UnpackTuple) := GetProc('PyArg_UnpackTuple');
  Pointer(Py_BuildValue)    := GetProc('Py_BuildValue');
  Pointer(Py_VaBuildValue)  := GetProc('Py_VaBuildValue');
  Pointer(PyModule_AddObject) := GetProc('PyModule_AddObject');
  Pointer(PyModule_AddIntConstant) := GetProc('PyModule_AddIntConstant');
  Pointer(PyModule_AddStringConstant) := GetProc('PyModule_AddStringConstant');
  Pointer(PyCFunction_NewEx) := GetProc('PyCFunction_NewEx');

  {$IFNDEF PY_LIMITED_API}
  Pointer(PyModule_AddFunctions) := GetProc('PyModule_AddFunctions');
  Pointer(PyCMethod_New)    := GetProc('PyCMethod_New');
  Pointer(PyModule_New)     := GetProc('PyModule_New');
  Pointer(PyModule_FromDefAndSpec2) := GetProc('PyModule_FromDefAndSpec2');
  Pointer(PyModule_ExecDef) := GetProc('PyModule_ExecDef');
  Pointer(PyModule_AddObjectRef) := GetProc('PyModule_AddObjectRef');
  Pointer(PyModule_Add)     := GetProc('PyModule_Add');
  Pointer(PyModule_SetDocString) := GetProc('PyModule_SetDocString');
  Pointer(PyModule_AddType) := GetProc('PyModule_AddType');
  {$ENDIF}
  Pointer(PyModule_GetNameObject) := GetProc('PyModule_GetNameObject');
  Pointer(PyModule_GetDef)  := GetProc('PyModule_GetDef');
  Pointer(PyModuleDef_Type) := GetProc('PyModuleDef_Type');
  Pointer(PyImport_ImportModule) := GetProc('PyImport_ImportModule');
end.
