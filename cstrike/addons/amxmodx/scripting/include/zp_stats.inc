#if defined _zp_stats_included
  #endinput
#endif
#define _zp_stats_included

// Вернет true в случае успешной установки
// или false в случае ошибки
native zps_set_user_money( id, money );

// Вернет деньги игрока
native zps_get_user_money( id );

// Вернет true в случае успешной установки
// или false в случае ошибки
native zps_set_user_exp( id, exp );

// Вернет кол-во exp игрока на текущем уровне
native zps_get_user_exp( id );

// Вернет true в случае успешной установки
// или false в случае ошибки
native zps_set_user_level( id, level );

// Вернет уровень игрока
native zps_get_user_level( id );


