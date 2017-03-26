package haxeFormatter.util;

class ArrayTools {
    public static inline function has<T>(a:Array<T>, e:T):Bool {
        return a != null && a.indexOf(e) != -1;
    }

    public static function last<T>(a:Array<T>):T {
        return a[a.length - 1];
    }
}