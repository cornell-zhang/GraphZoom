/*=================================================================
 * elimination.h
 *
 * Centralizes elimination constants.
 *=================================================================*/
#ifndef _ELIMINATION_H
#define _ELIMINATION_H

/* Node coding schema */
/* 0 = reserved value = node is not marked yet */
#define   LOW_DEGREE      1     // Low-degree nodes (F)
#define   HIGH_DEGREE     2     // High-degree nodes (C)
#define   ZERO_DEGREE     3     // Zero-degree nodes (marked before this function is called)
#define   NOT_ELIMINATED  4     // High or low degree, not in F to satisfy F's independence

#endif /* _ELIMINATION_H */
