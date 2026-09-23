#include "my_application.h"

#include <flutter_linux/flutter_linux.h>
#include <cstdio>
#ifdef GDK_WINDOWING_X11
#include <gdk/gdkx.h>
#endif

#include "flutter/generated_plugin_registrant.h"

struct _MyApplication {
  GtkApplication parent_instance;
  char** dart_entrypoint_arguments;
};

G_DEFINE_TYPE(MyApplication, my_application, GTK_TYPE_APPLICATION)

// 取视窗所在显示器的工作区（逻辑像素，已扣掉顶栏/任务栏）。
// 拿不到显示器时回传 FALSE，调用方自行取默认值。
static gboolean get_monitor_workarea(GtkWindow* window, GdkRectangle* workarea) {
  GdkDisplay* display = gtk_widget_get_display(GTK_WIDGET(window));
  GdkMonitor* monitor = gdk_display_get_primary_monitor(display);
  if (monitor == nullptr) {
    monitor = gdk_display_get_monitor(display, 0);
  }
  if (monitor == nullptr) {
    return FALSE;
  }

  gdk_monitor_get_workarea(monitor, workarea);
  return TRUE;
}

// 手机预览：印出 Flutter 实际拿到的逻辑视口（尺寸有变才印），用来确认
// 「视窗尺寸 = 手机 dp 数」这件事真的成立（拉伸视窗时同步更新）。
static void view_size_allocate_cb(GtkWidget* widget, GdkRectangle* allocation,
                                  gpointer user_data) {
  static int last_width = 0;
  static int last_height = 0;
  if (allocation->width == last_width && allocation->height == last_height) {
    return;
  }

  last_width = allocation->width;
  last_height = allocation->height;
  g_print("[preview] Flutter 视口 %d x %d dp\n", last_width, last_height);
}

// Implements GApplication::activate.
static void my_application_activate(GApplication* application) {
  MyApplication* self = MY_APPLICATION(application);
  GtkWindow* window =
      GTK_WINDOW(gtk_application_window_new(GTK_APPLICATION(application)));

  // Use a header bar when running in GNOME as this is the common style used
  // by applications and is the setup most users will be using (e.g. Ubuntu
  // desktop).
  // If running on X and not using GNOME then just use a traditional title bar
  // in case the window manager does more exotic layout, e.g. tiling.
  // If running on Wayland assume the header bar will work (may need changing
  // if future cases occur).
  gboolean use_header_bar = TRUE;
#ifdef GDK_WINDOWING_X11
  GdkScreen* screen = gtk_window_get_screen(window);
  if (GDK_IS_X11_SCREEN(screen)) {
    const gchar* wm_name = gdk_x11_screen_get_window_manager_name(screen);
    if (g_strcmp0(wm_name, "GNOME Shell") != 0) {
      use_header_bar = FALSE;
    }
  }
#endif
  if (use_header_bar) {
    GtkHeaderBar* header_bar = GTK_HEADER_BAR(gtk_header_bar_new());
    gtk_widget_show(GTK_WIDGET(header_bar));
    gtk_header_bar_set_title(header_bar, "beecount");
    gtk_header_bar_set_show_close_button(header_bar, TRUE);
    gtk_window_set_titlebar(window, GTK_WIDGET(header_bar));
  } else {
    gtk_window_set_title(window, "beecount");
  }

  // 手机预览视窗尺寸。重点是：这里设的就是 Flutter 看到的逻辑尺寸（dp）——
  // Linux embedder 拿 GTK 的 allocation 当逻辑尺寸、pixel_ratio 取 GTK 的整数
  // 缩放因子（engine 的 fl_view.cc handle_geometry_changed），所以「视窗多大
  // dp，视口就多大 dp」，放大视窗并不会放大画面，只会把布局撑到更宽/更高的
  // 逻辑尺寸。2026-09 之前那版乘 1.6 倍就有这个毛病：手机形状的视窗里跑的其实
  // 是 ~450dp 宽的平板布局，看起来又宽又松。
  //
  // 预设尺寸取真实流量里最主流的几档（DeviceAtlas 2026-05、2040 万笔移动端
  // 样本：宽度 360/384/412dp 各约 17~18%；iPhone 端 390x844 占 18.9%，是最大
  // 单档），依序挑第一个能放进显示器工作区的。旧值 375x667 是 2014 年 iPhone 6
  // 的 16:9 视口，比 19.5:9 的现代机少了约 180dp 高度，底部导航/长列表会显得挤。
  static const struct {
    int width;
    int height;
  } kPhonePresets[] = {
      {390, 844},  // 现代主流：iPhone 12–16 基款 / 多数 Android 旗舰
      {360, 780},  // Android 最常见宽度：Galaxy S 基款、多数平价机
      {320, 568},  // 保底：系统显示缩放/无障碍放大后的现代机
  };

  int phone_w = kPhonePresets[0].width;
  int phone_h = kPhonePresets[0].height;

  // 临时换尺寸（不限预设）用 BEECOUNT_PREVIEW_SIZE=412x915，见 docs/contributing。
  const gchar* size_override = g_getenv("BEECOUNT_PREVIEW_SIZE");
  gboolean overridden = FALSE;
  if (size_override != nullptr) {
    int width = 0;
    int height = 0;
    if (sscanf(size_override, "%dx%d", &width, &height) == 2 && width > 0 &&
        height > 0) {
      phone_w = width;
      phone_h = height;
      overridden = TRUE;
    } else {
      g_warning("BEECOUNT_PREVIEW_SIZE 需要「宽x高」（dp），已忽略：%s",
                size_override);
    }
  }

  // GTK 的视窗尺寸就是内容区尺寸：实测（GTK 3.24）Flutter 视口恰好等于这里
  // 设的值，CSD 标头列是另外加在视窗上的，不需要补偿；走传统标题列时装饰也画
  // 在视窗外。启动日志会印出实际视口供核对。
  if (!overridden) {
    GdkRectangle workarea;
    if (get_monitor_workarea(window, &workarea)) {
      for (gsize i = 0; i < G_N_ELEMENTS(kPhonePresets); i++) {
        // 每档都先假设可用；放不下就退到下一档（都放不下则用最小的那档）。
        phone_w = kPhonePresets[i].width;
        phone_h = kPhonePresets[i].height;
        if (phone_w <= workarea.width * 0.95 &&
            phone_h <= workarea.height * 0.95) {
          break;
        }
      }
    }
  }

  g_print("[preview] 手机预设 %d x %d dp%s\n", phone_w, phone_h,
          overridden ? "，来自 BEECOUNT_PREVIEW_SIZE" : "");
  gtk_window_set_default_size(window, phone_w, phone_h);

  gtk_widget_show(GTK_WIDGET(window));

  g_autoptr(FlDartProject) project = fl_dart_project_new();
  fl_dart_project_set_dart_entrypoint_arguments(project, self->dart_entrypoint_arguments);

  FlView* view = fl_view_new(project);
  gtk_widget_show(GTK_WIDGET(view));
  g_signal_connect(view, "size-allocate", G_CALLBACK(view_size_allocate_cb),
                   nullptr);
  gtk_container_add(GTK_CONTAINER(window), GTK_WIDGET(view));

  fl_register_plugins(FL_PLUGIN_REGISTRY(view));

  gtk_widget_grab_focus(GTK_WIDGET(view));
}

// Implements GApplication::local_command_line.
static gboolean my_application_local_command_line(GApplication* application, gchar*** arguments, int* exit_status) {
  MyApplication* self = MY_APPLICATION(application);
  // Strip out the first argument as it is the binary name.
  self->dart_entrypoint_arguments = g_strdupv(*arguments + 1);

  g_autoptr(GError) error = nullptr;
  if (!g_application_register(application, nullptr, &error)) {
     g_warning("Failed to register: %s", error->message);
     *exit_status = 1;
     return TRUE;
  }

  g_application_activate(application);
  *exit_status = 0;

  return TRUE;
}

// Implements GApplication::startup.
static void my_application_startup(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application startup.

  G_APPLICATION_CLASS(my_application_parent_class)->startup(application);
}

// Implements GApplication::shutdown.
static void my_application_shutdown(GApplication* application) {
  //MyApplication* self = MY_APPLICATION(object);

  // Perform any actions required at application shutdown.

  G_APPLICATION_CLASS(my_application_parent_class)->shutdown(application);
}

// Implements GObject::dispose.
static void my_application_dispose(GObject* object) {
  MyApplication* self = MY_APPLICATION(object);
  g_clear_pointer(&self->dart_entrypoint_arguments, g_strfreev);
  G_OBJECT_CLASS(my_application_parent_class)->dispose(object);
}

static void my_application_class_init(MyApplicationClass* klass) {
  G_APPLICATION_CLASS(klass)->activate = my_application_activate;
  G_APPLICATION_CLASS(klass)->local_command_line = my_application_local_command_line;
  G_APPLICATION_CLASS(klass)->startup = my_application_startup;
  G_APPLICATION_CLASS(klass)->shutdown = my_application_shutdown;
  G_OBJECT_CLASS(klass)->dispose = my_application_dispose;
}

static void my_application_init(MyApplication* self) {}

MyApplication* my_application_new() {
  // Set the program name to the application ID, which helps various systems
  // like GTK and desktop environments map this running application to its
  // corresponding .desktop file. This ensures better integration by allowing
  // the application to be recognized beyond its binary name.
  g_set_prgname(APPLICATION_ID);

  return MY_APPLICATION(g_object_new(my_application_get_type(),
                                     "application-id", APPLICATION_ID,
                                     "flags", G_APPLICATION_NON_UNIQUE,
                                     nullptr));
}
