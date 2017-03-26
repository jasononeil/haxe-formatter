package haxeFormatter;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import haxeFormatter.util.MacroStructTools;
using Lambda;

class StructInversionMacro {
    public static macro function invert(struct:Expr):Expr {
        var fields = MacroStructTools.getFields(Context.typeof(struct));
        if (fields == null)
            Context.fatalError("Unable to retrieve struct fields", (macro 0).pos);
        return generateInversions(fields, struct);
    }

    static function generateInversions(fields:Array<ClassField>, struct:Expr):Expr {
        var inversions = [];
        for (field in fields) {
            var name = field.name;
            switch (field.type) {
                case TType(_, [TAbstract(_.get() => type, [])]):
                    if (type.name == "Bool") {
                        inversions.push(macro {
                            $struct.$name = !$struct.$name;
                        });
                    } else if (type.impl != null && type.impl.get().statics.get().exists(
                        function(field) return field.name == "inverted")) {
                        inversions.push(macro {
                            $struct.$name = $struct.$name.inverted();
                        });
                    }
                case TType(_, params) if (params.length > 0): // recurse
                    var innerFields = MacroStructTools.getFields(params[0]);
                    if (innerFields != null)
                        inversions.push(generateInversions(
                            innerFields, macro {$struct.$name;}
                        ));
                case _:
            }
        }
        return macro {
            if ($struct != null)
                $b {inversions}
        };
    }
}