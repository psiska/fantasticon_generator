const String base = '''
// GENERATED CODE - DO NOT MODIFY BY HAND

import 'package:flutter/widgets.dart';

@immutable
class _%CLASS_NAME%Data extends IconData {
%INDENT%const _%CLASS_NAME%Data(int codePoint)
%INDENT%%INDENT%%INDENT%: super(
%INDENT%%INDENT%%INDENT%%INDENT%%INDENT%codePoint,
%INDENT%%INDENT%%INDENT%%INDENT%%INDENT%fontFamily: '%CLASS_NAME%',%PACKAGE%
%INDENT%%INDENT%%INDENT%%INDENT%);
}

@immutable
class %CLASS_NAME% {
%INDENT%%CLASS_NAME%._();

%INDENT%static Map<String, dynamic> _toMap() {
%INDENT%%INDENT%return {
%INDENT%%INDENT%%INDENT%%MAP%
%INDENT%%INDENT%};
}

%INDENT%static dynamic has(String propertyName) {
%INDENT%%INDENT%var _mapRep = _toMap();
%INDENT%%INDENT%return _mapRep.containsKey(propertyName);
%INDENT%}

%INDENT%static dynamic get(String propertyName) {
%INDENT%%INDENT%var _mapRep = _toMap();
%INDENT%%INDENT%if (_mapRep.containsKey(propertyName)) {
%INDENT%%INDENT%%INDENT%return _mapRep[propertyName];
%INDENT%%INDENT%}
%INDENT%%INDENT%throw ArgumentError('Icon not found');
%INDENT%}

%INDENT%
%CONTENT%
}
''';

const String icon_map = "'%ICON_NAME%': %ICON_NAME%";

const String icon = '%INDENT%static const IconData %ICON_NAME% = '
    '_%CLASS_NAME%Data(0x%ICON_CODE%);';

const String package = '\n%INDENT%%INDENT%%INDENT%%INDENT%'
    '%INDENT%fontPackage: \'%PACKAGE_NAME%\',';
