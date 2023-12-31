{{
  config(
    materialized = "table"
  )
}}

with cte_draft_year as ( 
-- This cte pulls in each player's Draft info for analysis. Players in years before we have data will have null values
select 
    
    player_name,
    draft_year,
    draft_rnd,
    draft_pick_num,
    draft_team,
    draft_position,
    college

from {{ ref('int_fb__draft_results') }}

) 


select

    sta.sk_id,
    
    sta.player_id,
    sta.player_name,
    
    sta.position,
    sta.team,
    sta.season,
    sta.week_num,
    sta.game_id,
    sta.opponent,

    sta.pass_yds,
    sta.pass_td,
    sta.pass_int,
    sta.rush_yds,
    sta.rush_td,
    sta.recs,
    sta.rec_yds,
    sta.rec_td,
    sta.def_sack,
    sta.def_int,
    sta.def_fumb_forced,
    sta.def_fumb_recovered,

    sta.fantasy_pts_std,
    sta.fantasy_pts_hppr,
    sta.fantasy_pts_ppr,

    dra.draft_year,
    dra.draft_rnd,
    dra.draft_pick_num,
    dra.draft_team,
    dra.draft_position,
    dra.college,

    (sta.season = dra.draft_year) as is_rookie_season,
    (cast(sta.season as integer) - cast(dra.draft_year as integer) + 1) as career_season_num,

    row_number() over (partition by sta.player_name, sta.position, sta.season order by sta.week_num asc ) as season_game_num,
    -- Teams have 1 bye-week (rest week) each season. This counts the number of games each player has played in each season to avoid missing values in trend view

from {{ ref('int_fb__weekly_stats_enhanced') }} sta 

left join cte_draft_year dra 
    on case 
        when sta.is_dupe_name is true 
            then (sta.dupe_draft_year = dra.draft_year 
            and sta.dupe_pick_num = dra.draft_pick_num)
        else sta.player_name = dra.player_name
    end  
