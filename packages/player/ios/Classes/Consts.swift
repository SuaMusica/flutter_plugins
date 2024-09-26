//
//  Consts.swift
//  AFNetworking
//
//  Created by Lucas Tonussi on 25/09/24.
//
import Foundation
//CHANNEL METHODS
let INITIALIZE_METHOD = "initialize"
let SEEK_METHOD = "seek"
let PREVIOUS_METHOD = "previous"
let STOP_METHOD = "stop"
let RESUME_METHOD = "resume"
let PLAY_METHOD = "play"
let PLAY_EXTERNAL_METHOD = "play_external"
let PAUSE_METHOD = "pause"
let PAUSE_EXTERNAL_METHOD = "pause_external"
let NEXT_METHOD = "next"
let ENQUEUE_METHOD = "enqueue"
let CLEAR_QUEUE = "clear_queue"
let RETURN_QUEUE = "return_queue"
let REORDER_QUEUE = "reorder_queue"
let TOGGLE_FAVORITE = "toggle_favorite"
let TOGGLE_SHUFFLE = "toggle_shuffle"
let REPEAT_MODE = "repeat_mode"
let DELETE_ITEM_IN_QUEUE = "delete_item_in_queue"
let PLAY_ITEM_QUEUE_FROM_INDEX = "play_item_queue_from_index"
let GET_EXTRAS = "get_extras"
let UPDATE_FAVORITE_ICON = "update_favorite_icon"
let CONTINUE_TO_PLAY = "continue_to_play"
let SHOW_LOG_IN_RELEASE = "show_log_in_release"
let TOGGLE_EXTERNAL_PLAYER = "toggle_external_player"
let UPDATE_ADS_TAG = "update_ads_tag"
let UPDATE_SHOULD_SHOW_ADS = "update_should_show_ads"
//ARGS CHANNEL
let PLAYER_ID_ARGS = "player_id_args"
let ADS_EVENT_ARGS = "ads_event_args"
let ADS_EVENT_IS_AUDIO = "ads_event_is_audio"
let ADS_CODE_ERROR_ARGS = "ads_code_error_args"
let ADS_MESSAGE_ERROR_ARGS = "ads_message_error_args"
let POSITION_ARGS = "position"
let SHUFFLE_ARGS = "shuffle_args"
let CURRENT_MEDIA_INDEX_ARGS = "current_media_index_args"
let DURATION_ARGS = "duration"
let STATE_ARGS = "state"
let ITS_AD_TIME = "its_ad_time"
let ERROR_ARGS = "error_args"
let QUEUE_ARGS = "queue_args"
let EXTRAS_ARGS = "extras_args"
let IS_FAVORITE_ARGS = "is_favorite_args"
let REPEAT_MODE_ARGS = "repeat_mode_args"
let EVENT_ARGS = "event_args"

//EVENTS CHANNEL
let POSITION_CHANGE = "position_change"
let REPEAT_MODE_CHANGED = "repeat_mode_changed"
let SHUFFLE_CHANGED = "shuffle_changed"
let ON_ADS = "on_ads"
let NOTIFY_PLAYER_EXTERNAL = "notify_player_external"
let STATE_CHANGE = "state_change"
let CURRENT_QUEUE = "current_queue"
let FAVORITE_UPDATE = "favorite_update"
