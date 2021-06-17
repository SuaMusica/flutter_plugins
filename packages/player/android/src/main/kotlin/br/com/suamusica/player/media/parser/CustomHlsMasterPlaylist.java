package br.com.suamusica.player.media.parser;

import android.net.Uri;

import androidx.annotation.Nullable;

import com.google.android.exoplayer2.Format;
import com.google.android.exoplayer2.drm.DrmInitData;
import com.google.android.exoplayer2.offline.StreamKey;
import com.google.android.exoplayer2.source.hls.playlist.HlsPlaylist;
import com.google.android.exoplayer2.util.MimeTypes;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

public final class CustomHlsMasterPlaylist extends HlsPlaylist {

    /** Represents an empty master playlist, from which no attributes can be inherited. */
    public static final CustomHlsMasterPlaylist EMPTY =
            new CustomHlsMasterPlaylist(
                    /* baseUri= */ "",
                    /* tags= */ new ArrayList<String>(),
                    /* variants= */ new ArrayList<Variant>(),
                    /* videos= */ new ArrayList<Rendition>(),
                    /* audios= */ new ArrayList<Rendition>(),
                    /* subtitles= */ new ArrayList<Rendition>(),
                    /* closedCaptions= */ new ArrayList<Rendition>(),
                    /* muxedAudioFormat= */ null,
                    /* muxedCaptionFormats= */ new ArrayList<Format>(),
                    /* hasIndependentSegments= */ false,
                    /* variableDefinitions= */ new HashMap<String, String>(),
                    /* sessionKeyDrmInitData= */ new ArrayList<DrmInitData>());

    // These constants must not be changed because they are persisted in offline stream keys.
    public static final int GROUP_INDEX_VARIANT = 0;
    public static final int GROUP_INDEX_AUDIO = 1;
    public static final int GROUP_INDEX_SUBTITLE = 2;

    /** A variant (i.e. an #EXT-X-STREAM-INF tag) in a master playlist. */
    public static final class Variant {

        /** The variant's url. */
        public final Uri url;

        /** Format information associated with this variant. */
        public final Format format;

        /** The video rendition group referenced by this variant, or {@code null}. */
        @Nullable
        public final String videoGroupId;

        /** The audio rendition group referenced by this variant, or {@code null}. */
        @Nullable public final String audioGroupId;

        /** The subtitle rendition group referenced by this variant, or {@code null}. */
        @Nullable public final String subtitleGroupId;

        /** The caption rendition group referenced by this variant, or {@code null}. */
        @Nullable public final String captionGroupId;

        /**
         * @param url See {@link #url}.
         * @param format See {@link #format}.
         * @param videoGroupId See {@link #videoGroupId}.
         * @param audioGroupId See {@link #audioGroupId}.
         * @param subtitleGroupId See {@link #subtitleGroupId}.
         * @param captionGroupId See {@link #captionGroupId}.
         */
        public Variant(
                Uri url,
                Format format,
                @Nullable String videoGroupId,
                @Nullable String audioGroupId,
                @Nullable String subtitleGroupId,
                @Nullable String captionGroupId) {
            this.url = url;
            this.format = format;
            this.videoGroupId = videoGroupId;
            this.audioGroupId = audioGroupId;
            this.subtitleGroupId = subtitleGroupId;
            this.captionGroupId = captionGroupId;
        }

        /**
         * Creates a variant for a given media playlist url.
         *
         * @param url The media playlist url.
         * @return The variant instance.
         */
        public static CustomHlsMasterPlaylist.Variant createMediaPlaylistVariantUrl(Uri url) {
            Format format =
                    Format.createContainerFormat(
                            "0",
                            /* label= */ null,
                            MimeTypes.APPLICATION_M3U8,
                            /* sampleMimeType= */ null,
                            /* codecs= */ null,
                            /* bitrate= */ Format.NO_VALUE,
                            /* selectionFlags= */ 0,
                            /* roleFlags= */ 0,
                            /* language= */ null);
            return new CustomHlsMasterPlaylist.Variant(
                    url,
                    format,
                    /* videoGroupId= */ null,
                    /* audioGroupId= */ null,
                    /* subtitleGroupId= */ null,
                    /* captionGroupId= */ null);
        }

        /** Returns a copy of this instance with the given {@link Format}. */
        public CustomHlsMasterPlaylist.Variant copyWithFormat(Format format) {
            return new CustomHlsMasterPlaylist.Variant(url, format, videoGroupId, audioGroupId, subtitleGroupId, captionGroupId);
        }
    }

    /** A rendition (i.e. an #EXT-X-MEDIA tag) in a master playlist. */
    public static final class Rendition {

        /** The rendition's url, or null if the tag does not have a URI attribute. */
        @Nullable public final Uri url;

        /** Format information associated with this rendition. */
        public final Format format;

        /** The group to which this rendition belongs. */
        public final String groupId;

        /** The name of the rendition. */
        public final String name;

        /**
         * @param url See {@link #url}.
         * @param format See {@link #format}.
         * @param groupId See {@link #groupId}.
         * @param name See {@link #name}.
         */
        public Rendition(@Nullable Uri url, Format format, String groupId, String name) {
            this.url = url;
            this.format = format;
            this.groupId = groupId;
            this.name = name;
        }

    }

    /** All of the media playlist URLs referenced by the playlist. */
    public final List<Uri> mediaPlaylistUrls;
    /** The variants declared by the playlist. */
    public final List<CustomHlsMasterPlaylist.Variant> variants;
    /** The video renditions declared by the playlist. */
    public final List<CustomHlsMasterPlaylist.Rendition> videos;
    /** The audio renditions declared by the playlist. */
    public final List<CustomHlsMasterPlaylist.Rendition> audios;
    /** The subtitle renditions declared by the playlist. */
    public final List<CustomHlsMasterPlaylist.Rendition> subtitles;
    /** The closed caption renditions declared by the playlist. */
    public final List<CustomHlsMasterPlaylist.Rendition> closedCaptions;

    /**
     * The format of the audio muxed in the variants. May be null if the playlist does not declare any
     * muxed audio.
     */
    public final Format muxedAudioFormat;
    /**
     * The format of the closed captions declared by the playlist. May be empty if the playlist
     * explicitly declares no captions are available, or null if the playlist does not declare any
     * captions information.
     */
    public final List<Format> muxedCaptionFormats;
    /** Contains variable definitions, as defined by the #EXT-X-DEFINE tag. */
    public final Map<String, String> variableDefinitions;
    /** DRM initialization data derived from #EXT-X-SESSION-KEY tags. */
    public final List<DrmInitData> sessionKeyDrmInitData;

    /**
     * @param baseUri See {@link #baseUri}.
     * @param tags See {@link #tags}.
     * @param variants See {@link #variants}.
     * @param videos See {@link #videos}.
     * @param audios See {@link #audios}.
     * @param subtitles See {@link #subtitles}.
     * @param closedCaptions See {@link #closedCaptions}.
     * @param muxedAudioFormat See {@link #muxedAudioFormat}.
     * @param muxedCaptionFormats See {@link #muxedCaptionFormats}.
     * @param hasIndependentSegments See {@link #hasIndependentSegments}.
     * @param variableDefinitions See {@link #variableDefinitions}.
     * @param sessionKeyDrmInitData See {@link #sessionKeyDrmInitData}.
     */
    public CustomHlsMasterPlaylist(
            String baseUri,
            List<String> tags,
            List<CustomHlsMasterPlaylist.Variant> variants,
            List<CustomHlsMasterPlaylist.Rendition> videos,
            List<CustomHlsMasterPlaylist.Rendition> audios,
            List<CustomHlsMasterPlaylist.Rendition> subtitles,
            List<CustomHlsMasterPlaylist.Rendition> closedCaptions,
            Format muxedAudioFormat,
            List<Format> muxedCaptionFormats,
            boolean hasIndependentSegments,
            Map<String, String> variableDefinitions,
            List<DrmInitData> sessionKeyDrmInitData) {
        super(baseUri, tags, hasIndependentSegments);
        this.mediaPlaylistUrls =
                Collections.unmodifiableList(
                        getMediaPlaylistUrls(variants, videos, audios, subtitles, closedCaptions));
        this.variants = Collections.unmodifiableList(variants);
        this.videos = Collections.unmodifiableList(videos);
        this.audios = Collections.unmodifiableList(audios);
        this.subtitles = Collections.unmodifiableList(subtitles);
        this.closedCaptions = Collections.unmodifiableList(closedCaptions);
        this.muxedAudioFormat = muxedAudioFormat;
        this.muxedCaptionFormats = muxedCaptionFormats != null
                ? Collections.unmodifiableList(muxedCaptionFormats) : null;
        this.variableDefinitions = Collections.unmodifiableMap(variableDefinitions);
        this.sessionKeyDrmInitData = Collections.unmodifiableList(sessionKeyDrmInitData);
    }

    @Override
    public CustomHlsMasterPlaylist copy(List<StreamKey> streamKeys) {
        return new CustomHlsMasterPlaylist(
                baseUri,
                tags,
                copyStreams(variants, GROUP_INDEX_VARIANT, streamKeys),
                // TODO: Allow stream keys to specify video renditions to be retained.
                /* videos= */ new ArrayList<Rendition>(),
                copyStreams(audios, GROUP_INDEX_AUDIO, streamKeys),
                copyStreams(subtitles, GROUP_INDEX_SUBTITLE, streamKeys),
                // TODO: Update to retain all closed captions.
                /* closedCaptions= */ new ArrayList<Rendition>(),
                muxedAudioFormat,
                muxedCaptionFormats,
                hasIndependentSegments,
                variableDefinitions,
                sessionKeyDrmInitData);
    }

    /**
     * Creates a playlist with a single variant.
     *
     * @param variantUrl The url of the single variant.
     * @return A master playlist with a single variant for the provided url.
     */
    public static CustomHlsMasterPlaylist createSingleVariantMasterPlaylist(String variantUrl) {
        List<CustomHlsMasterPlaylist.Variant> variant =
                Collections.singletonList(CustomHlsMasterPlaylist.Variant.createMediaPlaylistVariantUrl(Uri.parse(variantUrl)));
        return new CustomHlsMasterPlaylist(
                /* baseUri= */ null,
                /* tags= */ new ArrayList<String>(),
                variant,
                /* videos= */ new ArrayList<Rendition>(),
                /* audios= */ new ArrayList<Rendition>(),
                /* subtitles= */ new ArrayList<Rendition>(),
                /* closedCaptions= */ new ArrayList<Rendition>(),
                /* muxedAudioFormat= */ null,
                /* muxedCaptionFormats= */ null,
                /* hasIndependentSegments= */ false,
                /* variableDefinitions= */ new HashMap<String, String>(),
                /* sessionKeyDrmInitData= */ new ArrayList<DrmInitData>());
    }

    private static List<Uri> getMediaPlaylistUrls(
            List<CustomHlsMasterPlaylist.Variant> variants,
            List<CustomHlsMasterPlaylist.Rendition> videos,
            List<CustomHlsMasterPlaylist.Rendition> audios,
            List<CustomHlsMasterPlaylist.Rendition> subtitles,
            List<CustomHlsMasterPlaylist.Rendition> closedCaptions) {
        ArrayList<Uri> mediaPlaylistUrls = new ArrayList<>();
        for (int i = 0; i < variants.size(); i++) {
            Uri uri = variants.get(i).url;
            if (!mediaPlaylistUrls.contains(uri)) {
                mediaPlaylistUrls.add(uri);
            }
        }
        addMediaPlaylistUrls(videos, mediaPlaylistUrls);
        addMediaPlaylistUrls(audios, mediaPlaylistUrls);
        addMediaPlaylistUrls(subtitles, mediaPlaylistUrls);
        addMediaPlaylistUrls(closedCaptions, mediaPlaylistUrls);
        return mediaPlaylistUrls;
    }

    private static void addMediaPlaylistUrls(List<CustomHlsMasterPlaylist.Rendition> renditions, List<Uri> out) {
        for (int i = 0; i < renditions.size(); i++) {
            Uri uri = renditions.get(i).url;
            if (uri != null && !out.contains(uri)) {
                out.add(uri);
            }
        }
    }

    private static <T> List<T> copyStreams(
            List<T> streams, int groupIndex, List<StreamKey> streamKeys) {
        List<T> copiedStreams = new ArrayList<>(streamKeys.size());
        // TODO:
        // 1. When variants with the same URL are not de-duplicated, duplicates must not increment
        //    trackIndex so as to avoid breaking stream keys that have been persisted for offline. All
        //    duplicates should be copied if the first variant is copied, or discarded otherwise.
        // 2. When renditions with null URLs are permitted, they must not increment trackIndex so as to
        //    avoid breaking stream keys that have been persisted for offline. All renitions with null
        //    URLs should be copied. They may become unreachable if all variants that reference them are
        //    removed, but this is OK.
        // 3. Renditions with URLs matching copied variants should always themselves be copied, even if
        //    the corresponding stream key is omitted. Else we're throwing away information for no gain.
        for (int i = 0; i < streams.size(); i++) {
            T stream = streams.get(i);
            for (int j = 0; j < streamKeys.size(); j++) {
                StreamKey streamKey = streamKeys.get(j);
                if (streamKey.groupIndex == groupIndex && streamKey.trackIndex == i) {
                    copiedStreams.add(stream);
                    break;
                }
            }
        }
        return copiedStreams;
    }

}