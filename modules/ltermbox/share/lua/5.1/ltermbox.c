#include <stdlib.h>
#include <string.h>
#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"
#include "termbox.h"

#define METATABLE_NAME "LT_BUFFER_METATABLE_NAME"
#define set_table(label, value) lua_pushnumber(L, value); \
                                lua_setfield(L, -2, label)
// cell userdata
typedef struct lt_buffer {
   unsigned int width;
   unsigned int height;
   struct tb_cell cell[1] ; // placeholder, you can't define array[0]
} lt_buffer; 

inline lt_buffer *get_buf(lua_State *L, int stackpos) {
   void *ud = luaL_checkudata(L, stackpos, METATABLE_NAME);
   luaL_argcheck(L, ud != NULL, stackpos, "`buffer' userdata expected");
   return (lt_buffer *)ud;
}
static int lt_new_buffer(lua_State *L) {
   unsigned int width = (unsigned int)luaL_checkint(L, 1);
   unsigned int height = (unsigned int)luaL_checkint(L, 2);
   int size = (sizeof(struct tb_cell) * width * height - 1) +
               sizeof(lt_buffer);

   lt_buffer *buf = (lt_buffer *) lua_newuserdata(L, size);
   buf->width = width;
   buf->height = height;

   luaL_getmetatable(L, METATABLE_NAME);
   lua_pushstring(L, "__index");
   lua_pushvalue(L, -2);
   lua_settable(L, -3);
   lua_setmetatable(L, -2);

   return 1;
}
static int lt_buf_size(lua_State *L) {
   lt_buffer *b = get_buf(L, 1);
   lua_pushinteger(L, b->width);
   lua_pushinteger(L, b->height);
   return 2;
}
#define GET_CELL(buf, x, y) &((buf)->cell[(y-1) * (buf)->width + (x-1)])
#define GET_CELL_PARAMS(start_from) unsigned int x = (unsigned int)luaL_checkint(L, start_from);\
   unsigned int y = (unsigned int)luaL_checkint(L, start_from+1);\
   uint32_t ch = (uint32_t)luaL_checknumber(L, start_from+2);\
   uint16_t fg = (uint16_t)luaL_checknumber(L, start_from+3);\
   uint16_t bg = (uint16_t)luaL_checknumber(L, start_from+4)

static int lt_buf_change_cell(lua_State *L) {
   lt_buffer *buf = get_buf(L, 1); // passed as `self'
   GET_CELL_PARAMS(2);
   struct tb_cell *c = GET_CELL(buf, x, y);
   c->ch = ch;
   c->fg = fg;
   c->bg = bg;
   return 0;
}
static int lt_buf_get_cell(lua_State *L) {
   lt_buffer *buf = get_buf(L, 1);
   unsigned int x = (unsigned int)luaL_checknumber(L, 2);
   unsigned int y = (unsigned int)luaL_checknumber(L, 3);
   struct tb_cell *c = GET_CELL(buf, x, y);
   lua_pushinteger(L, c->ch);
   lua_pushinteger(L, c->fg);
   lua_pushinteger(L, c->bg);
   return 3;
}
static int lt_buf_blit(lua_State *L){
   lt_buffer *buf = get_buf(L, 1);
   unsigned int x = (unsigned int)luaL_checknumber(L, 2);
   unsigned int y = (unsigned int)luaL_checknumber(L, 3);
   char param4 = lua_isnumber(L, 4);
   char param5 = lua_isnumber(L, 5);
   unsigned int head = param4 && param5 ? (lua_tonumber(L, 4)-1) : 0;
   unsigned int tail = (!param4)? buf->height : (
            param5? (lua_tonumber(L, 5)-1) : (lua_tonumber(L, 4)-1)
         );
   tb_blit(--x, --y, buf->width, tail, ((buf->cell)+head));
   return 0;
}
#define SHIFT_PARAMS \
   lt_buffer *buf = get_buf(L, 1);\
   int rows = 1;\
   if (lua_isnumber(L,2)) rows = lua_tonumber(L,2);\
   luaL_argcheck(L,(rows>0 && rows<buf->height), 2, "wrong number of rows");\
   size_t size = sizeof(struct tb_cell) * buf->width * (buf->height - rows);\
   struct tb_cell *c = ((buf->cell)+(rows*(buf->width)))
   // too lazy to read up on operator precedence ;)
static int lt_buf_shift_up(lua_State *L){
   SHIFT_PARAMS;
   memmove(buf->cell, c, size);
   return 0;
}
static int lt_buf_shift_down(lua_State *L){
   SHIFT_PARAMS;
   //    dest  src
   memmove(c, buf->cell, size);
   return 0;
}
#undef SHIFT_PARAMS
static const struct luaL_reg lt_buffer_metatable[] = {
   {"size", lt_buf_size},
   {"change_cell", lt_buf_change_cell},
   {"get_cell", lt_buf_get_cell},
   {"blit", lt_buf_blit},
   {"shift_up", lt_buf_shift_up},
   {"shift_down", lt_buf_shift_down},
   {NULL, NULL}
};
//api functions
static int lt_init(lua_State *L) {
   int i = tb_init();
   if (i < 0){
      if (i == TB_EUNSUPPORTED_TERMINAL)
         lua_pushstring(L, "Error, unsupported terminal.");
      if (i == TB_EFAILED_TO_OPEN_TTY)
         lua_pushstring(L, "Error, failed to open tty.");
      if (i == TB_EPIPE_TRAP_ERROR)
         lua_pushstring(L, "Error, epipe trap.");

      lua_error(L);
   }

   return 0;
}
static int lt_shutdown(lua_State *L){
   tb_shutdown();
   return 0;
}
static int lt_size(lua_State *L){
   lua_pushnumber(L, tb_width());
   lua_pushnumber(L, tb_height());
   return 2;
}
static int lt_clear(lua_State *L){
   tb_clear(); // clear buffer
   return 0;
}
static int lt_present(lua_State *L){
   tb_present(); // sync internal buffer with terminal
   return 0;
}
static int lt_set_cursor(lua_State *L){
   tb_set_cursor(luaL_checkint(L, 1), luaL_checkint(L, 2));
   return 0;
}
static int lt_hide_cursor(lua_State *L){
   tb_set_cursor(-1, -1);
   return 0;
}
static int lt_get_input_mode(lua_State *L){
   lua_pushnumber(L, tb_select_input_mode(-1));
   return 1;
}
static int lt_set_input_mode(lua_State *L){
   int mode = luaL_checkint(L, 1);
   if (mode != TB_INPUT_ALT || mode != TB_INPUT_ESC) {
      lua_pushstring(L, "Wrong input mode.");
      lua_error(L);
   }
   tb_select_input_mode(mode);
   return 0;
}
static int lt_change_cell(lua_State *L){
   GET_CELL_PARAMS(1);
   tb_change_cell(--x, --y, ch, fg, bg);
   return 0;
}
static int lt_peek_event(lua_State *L){
   struct tb_event ev;
   int ev_type = tb_peek_event(&ev, (unsigned int)luaL_checkint(L, 1)); 
   if (ev_type) {
      lua_createtable(L, 0, 6);
      set_table("type", ev.type);
      set_table("mod", ev.mod);
      set_table("key", ev.key);
      set_table("ch", ev.ch);
      set_table("width", ev.w);
      set_table("height", ev.h);
      return 1;
   } else {
      if (ev_type==0)
         return 0;
      lua_pushstring(L, "Error, input overflow/discarded input.");
      lua_error(L);
      return 0;
   }
}
//###########################################
static const struct luaL_reg ltermbox[] = {
   {"init", lt_init},
   {"shutdown", lt_shutdown},
   {"size", lt_size},

   {"change_cell", lt_change_cell},
   {"sync_buffer", lt_present},
   {"clear_buffer", lt_clear},

   {"set_cursor", lt_set_cursor},
   {"hide_cursor", lt_hide_cursor},
   {"set_mode", lt_set_input_mode},
   {"get_mode", lt_get_input_mode},

   {"peek_event", lt_peek_event},
   {"new_buffer", lt_new_buffer},
   {NULL, NULL}  /* sentinel */
};
LUALIB_API luaopen_ltermbox(lua_State *L) {
   luaL_newmetatable(L, METATABLE_NAME);
   luaL_register(L, NULL, lt_buffer_metatable);
   lua_pop(L, 1);

   luaL_register(L, "ltermbox", ltermbox); //leaves ltermbox table on top

   lua_createtable(L, 0, 2);
   set_table("esc", TB_INPUT_ESC);
   set_table("alt", TB_INPUT_ALT);
   set_table("get", 0);
   lua_setfield(L, -2, "mode");

   lua_createtable(L, 0, 10);
   set_table("black",TB_BLACK);
   set_table("red",TB_RED);
   set_table("green",TB_GREEN);
   set_table("yellow",TB_YELLOW);
   set_table("blue",TB_BLUE);
   set_table("magenta",TB_MAGENTA);
   set_table("cyan",TB_CYAN);
   set_table("white",TB_WHITE);
   set_table("bold",TB_BOLD);
   set_table("underline",TB_UNDERLINE);
   lua_setfield(L, -2, "attr");

   lua_newtable(L);
   set_table("f1", TB_KEY_F1);
   set_table("f2", TB_KEY_F2);
   set_table("f3", TB_KEY_F3);
   set_table("f4", TB_KEY_F4);
   set_table("f5", TB_KEY_F5);
   set_table("f6", TB_KEY_F6);
   set_table("f7", TB_KEY_F7);
   set_table("f8", TB_KEY_F8);
   set_table("f9", TB_KEY_F9);
   set_table("f10", TB_KEY_F10);
   set_table("f11", TB_KEY_F11);
   set_table("f12", TB_KEY_F12);
   set_table("ins", TB_KEY_INSERT);
   set_table("del", TB_KEY_DELETE);
   set_table("home", TB_KEY_HOME);
   set_table("end", TB_KEY_END);
   set_table("pgup", TB_KEY_PGUP);
   set_table("pgdown", TB_KEY_PGDN);
   set_table("up", TB_KEY_ARROW_UP);
   set_table("down", TB_KEY_ARROW_DOWN);
   set_table("left", TB_KEY_ARROW_LEFT);
   set_table("right", TB_KEY_ARROW_RIGHT);
   set_table("~", TB_KEY_CTRL_TILDE);
   set_table("c-2", TB_KEY_CTRL_2);
   set_table("c-a", TB_KEY_CTRL_A);
   set_table("c-b", TB_KEY_CTRL_B);
   set_table("c-c", TB_KEY_CTRL_C);
   set_table("c-d", TB_KEY_CTRL_D);
   set_table("c-e", TB_KEY_CTRL_E);
   set_table("c-f", TB_KEY_CTRL_F);
   set_table("c-g", TB_KEY_CTRL_G);
   set_table("backspace", TB_KEY_BACKSPACE);
   set_table("c-h", TB_KEY_CTRL_H);
   set_table("tab", TB_KEY_TAB);
   set_table("c-i", TB_KEY_CTRL_I);
   set_table("c-j", TB_KEY_CTRL_J);
   set_table("c-k", TB_KEY_CTRL_K);
   set_table("c-l", TB_KEY_CTRL_L);
   set_table("enter", TB_KEY_ENTER);
   set_table("c-m", TB_KEY_CTRL_M);
   set_table("c-n", TB_KEY_CTRL_N);
   set_table("c-o", TB_KEY_CTRL_O);
   set_table("c-p", TB_KEY_CTRL_P);
   set_table("c-q", TB_KEY_CTRL_Q);
   set_table("c-r", TB_KEY_CTRL_R);
   set_table("c-s", TB_KEY_CTRL_S);
   set_table("c-t", TB_KEY_CTRL_T);
   set_table("c-u", TB_KEY_CTRL_U);
   set_table("c-v", TB_KEY_CTRL_V);
   set_table("c-w", TB_KEY_CTRL_W);
   set_table("c-x", TB_KEY_CTRL_X);
   set_table("c-y", TB_KEY_CTRL_Y);
   set_table("c-z", TB_KEY_CTRL_Z);
   set_table("esc", TB_KEY_ESC);
   set_table("c-[", TB_KEY_CTRL_LSQ_BRACKET);
   set_table("c-3", TB_KEY_CTRL_3);
   set_table("c-4", TB_KEY_CTRL_4);
   set_table("c-\\", TB_KEY_CTRL_BACKSLASH);
   set_table("c-5", TB_KEY_CTRL_5);
   set_table("c-]", TB_KEY_CTRL_RSQ_BRACKET);
   set_table("c-6", TB_KEY_CTRL_6);
   set_table("c-7", TB_KEY_CTRL_7);
   set_table("c-/", TB_KEY_CTRL_SLASH);
   set_table("c-_", TB_KEY_CTRL_UNDERSCORE);
   set_table("c- ", TB_KEY_SPACE);
   set_table("backspace2", TB_KEY_BACKSPACE2);
   set_table("c-8", TB_KEY_CTRL_8);
   set_table("alt", TB_MOD_ALT);
   lua_setfield(L, -2, "key");

   lua_createtable(L, 0, 3);
   set_table("key", TB_EVENT_KEY);
   set_table("resize", TB_EVENT_RESIZE);
   set_table("none", 0);
   lua_setfield(L, -2, "event");
   return 1;
}
