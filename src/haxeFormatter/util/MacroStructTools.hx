package haxeFormatter.util;

import haxe.macro.Type;

class MacroStructTools {
    public static function getFields(type:Type):Array<ClassField> {
        return switch (type) {
            case TType(t, params):
                switch (t.get().type) {
                    case TAnonymous(a): a.get().fields;
                    case _: null;
                }
            case _: null;
        }
    }
}