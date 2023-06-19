import android.os.Build
import java.lang.reflect.Method

class EqualizerHelpers {

    fun isSpecialDevice(): Boolean {
        return isTecnoCamonDevice() || isMiuiVersionEqualsOrGreatherThan11()
    }

    fun isMiuiVersionEqualsOrGreatherThan11(): Boolean {
        try {
            val propertyClass =
                Class.forName("android.os.SystemProperties")
            val method: Method = propertyClass.getMethod("get", String::class.java)
            val versionName = method.invoke(propertyClass, "ro.miui.ui.version.name") as String
            if (versionName.isNullOrEmpty()) return false
            val numericVersionName = if (!versionName.startsWith("V")) versionName else versionName.substring(1)
            return numericVersionName.toInt() >= 11
        } catch (e: ClassNotFoundException) {
            e.printStackTrace()
        } catch (e: NoSuchMethodException) {
            e.printStackTrace()
        } catch (e: IllegalAccessException) {
            e.printStackTrace()
        }
        return false
    }

    fun isTecnoCamonDevice(): Boolean {
        return Build.MANUFACTURER == "Tecno" && Build.MODEL.contains("Camon")
    }
}