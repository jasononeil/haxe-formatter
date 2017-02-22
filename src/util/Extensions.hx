package util;

class Extensions {
    public static function has(s:String, substring:String):Bool {
        return s != null && s.indexOf(substring) != -1;
    }

    public static function idx<T>(a:Array<T>, i:Int) {
        return if (i >= 0) a[i] else a[a.length + i];
    }
}