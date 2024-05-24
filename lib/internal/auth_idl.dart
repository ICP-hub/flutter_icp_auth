import 'package:agent_dart/agent_dart.dart';

// Class for defining the IDL service for the whoAmI()
abstract class FieldsMethod {
  static const whoAmI = 'whoami';
  static final ServiceClass idl = IDL.Service(
    {
      FieldsMethod.whoAmI: IDL.Func([], [IDL.Text], []),
    },
  );
}
