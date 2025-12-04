{$mode fpc}
{$I config.inc}// ключи компиляции
library test;


uses
  ctypes,
  python,
  py_pymem,
  py_longobject,
  py_unicodeobject_ext,
  py_modsupport;

  function py_test(self, args: PPyObject): PPyObject; cdecl;
  var
    pylong: PPyObject;
  begin
    writeln('start');
    if PyArg_ParseTuple(args, 'O', @pylong) = 0 then
    begin
      writeln('Error -  PyArg_ParseTuple');
      Exit;
    end;
    Result := PyLong_FromLong(PyLong_AsLong(pylong) * 2);
  end;

  procedure Dump(P: Pointer; Len: integer);
  var
    i: integer;
  type
    bytearray = array[0..0] of byte;
  begin
    for i := 0 to Len - 1 do
    begin
      writeln(i:5, ': ', bytearray(P^)[i]:5, ' - ', (function(b: byte): string
      begin
        if b in [32..126] then Result := chr(b)
        else
          Result := ' ';
      end(bytearray(P^)[i])));
    end;
  end;

  //    Writeln(i, ':   ', bytearray(P^)[i], ' - ', chr(bytearray(P^)[i]));


  function py_str(self, args: PPyObject): PPyObject; cdecl;
  var
    pyStr: PPyObject;
  begin
    Result := nil;
    // Инициализируем результат как nil (ошибка по умолчанию)
    if PyArg_ParseTuple(args, 'O', @pyStr) = 0 then
    begin
      //   writeln('    if PyArg_ParseTuple(args, O, @pyStr) = 0 then');
      Exit;
    end;
    writeln('-');
    writeln('PyUnicode_KIND(pyStr)=', PyUnicode_KIND(pyStr));
    writeln('PyUnicode_IS_ASCII(pyStr)=', PyUnicode_IS_ASCII(pyStr));
    writeln('PyUnicode_IS_COMPACT(pyStr)=', PyUnicode_IS_COMPACT(pyStr));
    writeln('PyUnicode_CHECK_INTERNED(pyStr)=', PyUnicode_CHECK_INTERNED(pyStr));
    writeln('PyUnicode_GET_LENGTH(pyStr)=', PyUnicode_GET_LENGTH(pyStr));
    writeln('PyUnicode_IS_COMPACT_ASCII=', PyUnicode_IS_COMPACT_ASCII(pyStr));
    writeln('PyUnicode_GET_DATA_SIZE=', PyUnicode_GET_DATA_SIZE(pyStr));
    writeln('PyUnicode_MAX_CHAR_VALUE=', PyUnicode_MAX_CHAR_VALUE(pyStr));
    writeln(pyStr^.ob_type^.tp_flags);
    writeln('--------------');
    writeln(PyUnicode_READ_CHAR(pyStr, 0));
    writeln(PyUnicode_READ_CHAR(pyStr, 1));
    writeln(PyUnicode_READ_CHAR(pyStr, 2));
    writeln(PyUnicode_READ_CHAR(pyStr, 3));
    writeln('--------------', PyUnicode_GET_LENGTH(pyStr) * Ord(PyUnicode_KIND(pyStr)));
    Dump(PyUnicode_DATA(pyStr), PyUnicode_GET_LENGTH(pyStr) * Ord(PyUnicode_KIND(pyStr)));
    Result := PyLong_FromLong(PyUnicode_GET_LENGTH(pyStr));
  end;


  function py_test2(self, args: PPyObject): PPyObject; cdecl;
  var
    pylong:  PPyObject;
    paslong: clong;
  begin
    // Инициализируем результат как nil (ошибка по умолчанию)
    if PyArg_ParseTuple(args, 'O', @pylong) = 0 then
    begin
      writeln('Error -  PyArg_ParseTuple');
      Exit;
    end;
    writeln(Py_GetVersion);
    //    writeln(PyLong_Check(pylong));
    paslong := PyLong_AsLong(pylong);
    writeln(paslong);
    Result := PyLong_FromLong(paslong div 2);
  end;


{
  Определение методов модуля

  Это таблица, которая описывает все функции, доступные в модуле.
  Последний элемент должен быть заполнен нулями (nil).
}


const
  TestFunction1_def: PyMethodDef = (
    ml_name: 'py_test';
    ml_meth: @py_test;
    ml_flags: METH_VARARGS;
    ml_doc: 'First test function'
    );
  TestFunction2_def: PyMethodDef = (
    ml_name: 'py_str';
    ml_meth: @py_str;
    ml_flags: METH_VARARGS;
    ml_doc: '2First test function'
    );

const
  //  TestModuleDef: PyModuleDef = ();


  Test_ModuleDef: PyModuleDef = ();




  function PyInit_test: PPyObject; cdecl;
  begin
    Result := Init(Test_ModuleDef, 'test');
    if Assigned(Result) then
      Add(Result, @TestFunction1_def);
    Add(Result, @TestFunction2_def);
  end;

exports
  PyInit_test;

begin
end.
