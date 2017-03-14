package util;

class ArrayTools {
    public static inline function has<T>(a:Array<T>, e:T):Bool {
        return a != null && a.indexOf(e) != -1;
    }
}