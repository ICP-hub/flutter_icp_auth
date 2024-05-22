import 'package:agent_dart/agent_dart.dart';

abstract class FieldsMethod {
  static const whoAmI = 'whoami';
  static final ServiceClass idl = IDL.Service(
    {
      FieldsMethod.whoAmI: IDL.Func([], [IDL.Text], []),
    },
  );
}
