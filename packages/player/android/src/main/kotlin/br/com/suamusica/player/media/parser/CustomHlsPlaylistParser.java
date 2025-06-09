package br.com.suamusica.player.media.parser;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.URLEncoder;
import java.util.ArrayDeque;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Queue;
import java.util.TreeMap;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

import androidx.annotation.OptIn;
import androidx.media3.common.C;
import androidx.media3.common.Format;
import androidx.media3.common.ParserException;
import androidx.media3.common.DrmInitData;
//import androidx.media3.exoplayer.extractor.mp4.PsshAtomUtil;
import androidx.media3.common.Metadata;
import androidx.media3.common.util.Assertions;
import androidx.media3.common.util.UnstableApi;
import androidx.media3.common.util.UriUtil;
import androidx.media3.common.util.Util;
import androidx.media3.exoplayer.source.UnrecognizedInputFormatException;
import androidx.media3.exoplayer.hls.HlsTrackMetadataEntry;
import androidx.media3.exoplayer.hls.playlist.HlsMediaPlaylist;
import androidx.media3.exoplayer.hls.playlist.HlsPlaylist;
import androidx.media3.exoplayer.upstream.ParsingLoadable;
//import androidx.media3.exoplayer.util.Assertions;
import androidx.media3.common.MimeTypes;
//import com.google.android.exoplayer2.util.UriUtil;
//import com.google.android.exoplayer2.util.Util;

import android.util.Log;

import android.net.Uri;
import android.text.TextUtils;
import android.util.Base64;

import androidx.annotation.Nullable;
import androidx.media3.extractor.mp4.PsshAtomUtil;

@UnstableApi
public class CustomHlsPlaylistParser implements ParsingLoadable.Parser<HlsPlaylist> {

    private static final String PLAYLIST_HEADER = "#EXTM3U";

    private static final String TAG_PREFIX = "#EXT";

    private static final String TAG_VERSION = "#EXT-X-VERSION";
    private static final String TAG_PLAYLIST_TYPE = "#EXT-X-PLAYLIST-TYPE";
    private static final String TAG_DEFINE = "#EXT-X-DEFINE";
    private static final String TAG_STREAM_INF = "#EXT-X-STREAM-INF";
    private static final String TAG_MEDIA = "#EXT-X-MEDIA";
    private static final String TAG_TARGET_DURATION = "#EXT-X-TARGETDURATION";
    private static final String TAG_DISCONTINUITY = "#EXT-X-DISCONTINUITY";
    private static final String TAG_DISCONTINUITY_SEQUENCE = "#EXT-X-DISCONTINUITY-SEQUENCE";
    private static final String TAG_PROGRAM_DATE_TIME = "#EXT-X-PROGRAM-DATE-TIME";
    private static final String TAG_INIT_SEGMENT = "#EXT-X-MAP";
    private static final String TAG_INDEPENDENT_SEGMENTS = "#EXT-X-INDEPENDENT-SEGMENTS";
    private static final String TAG_MEDIA_DURATION = "#EXTINF";
    private static final String TAG_MEDIA_SEQUENCE = "#EXT-X-MEDIA-SEQUENCE";
    private static final String TAG_START = "#EXT-X-START";
    private static final String TAG_ENDLIST = "#EXT-X-ENDLIST";
    private static final String TAG_KEY = "#EXT-X-KEY";
    private static final String TAG_SESSION_KEY = "#EXT-X-SESSION-KEY";
    private static final String TAG_BYTERANGE = "#EXT-X-BYTERANGE";
    private static final String TAG_GAP = "#EXT-X-GAP";

    private static final String TYPE_AUDIO = "AUDIO";
    private static final String TYPE_VIDEO = "VIDEO";
    private static final String TYPE_SUBTITLES = "SUBTITLES";
    private static final String TYPE_CLOSED_CAPTIONS = "CLOSED-CAPTIONS";

    private static final String METHOD_NONE = "NONE";
    private static final String METHOD_AES_128 = "AES-128";
    private static final String METHOD_SAMPLE_AES = "SAMPLE-AES";
    // Replaced by METHOD_SAMPLE_AES_CTR. Keep for backward compatibility.
    private static final String METHOD_SAMPLE_AES_CENC = "SAMPLE-AES-CENC";
    private static final String METHOD_SAMPLE_AES_CTR = "SAMPLE-AES-CTR";
    private static final String KEYFORMAT_PLAYREADY = "com.microsoft.playready";
    private static final String KEYFORMAT_IDENTITY = "identity";
    private static final String KEYFORMAT_WIDEVINE_PSSH_BINARY =
            "urn:uuid:edef8ba9-79d6-4ace-a3c8-27dcd51d21ed";
    private static final String KEYFORMAT_WIDEVINE_PSSH_JSON = "com.widevine";

    private static final String BOOLEAN_TRUE = "YES";
    private static final String BOOLEAN_FALSE = "NO";

    private static final String ATTR_CLOSED_CAPTIONS_NONE = "CLOSED-CAPTIONS=NONE";

    private static final Pattern REGEX_AVERAGE_BANDWIDTH =
            Pattern.compile("AVERAGE-BANDWIDTH=(\\d+)\\b");
    private static final Pattern REGEX_VIDEO = Pattern.compile("VIDEO=\"(.+?)\"");
    private static final Pattern REGEX_AUDIO = Pattern.compile("AUDIO=\"(.+?)\"");
    private static final Pattern REGEX_SUBTITLES = Pattern.compile("SUBTITLES=\"(.+?)\"");
    private static final Pattern REGEX_CLOSED_CAPTIONS = Pattern.compile("CLOSED-CAPTIONS=\"(.+?)\"");
    private static final Pattern REGEX_BANDWIDTH = Pattern.compile("[^-]BANDWIDTH=(\\d+)\\b");
    private static final Pattern REGEX_CHANNELS = Pattern.compile("CHANNELS=\"(.+?)\"");
    private static final Pattern REGEX_CODECS = Pattern.compile("CODECS=\"(.+?)\"");
    private static final Pattern REGEX_RESOLUTION = Pattern.compile("RESOLUTION=(\\d+x\\d+)");
    private static final Pattern REGEX_FRAME_RATE = Pattern.compile("FRAME-RATE=([\\d\\.]+)\\b");
    private static final Pattern REGEX_TARGET_DURATION = Pattern.compile(TAG_TARGET_DURATION
            + ":(\\d+)\\b");
    private static final Pattern REGEX_VERSION = Pattern.compile(TAG_VERSION + ":(\\d+)\\b");
    private static final Pattern REGEX_PLAYLIST_TYPE = Pattern.compile(TAG_PLAYLIST_TYPE
            + ":(.+)\\b");
    private static final Pattern REGEX_MEDIA_SEQUENCE = Pattern.compile(TAG_MEDIA_SEQUENCE
            + ":(\\d+)\\b");
    private static final Pattern REGEX_MEDIA_DURATION = Pattern.compile(TAG_MEDIA_DURATION
            + ":([\\d\\.]+)\\b");
    private static final Pattern REGEX_MEDIA_TITLE =
            Pattern.compile(TAG_MEDIA_DURATION + ":[\\d\\.]+\\b,(.+)");
    private static final Pattern REGEX_TIME_OFFSET = Pattern.compile("TIME-OFFSET=(-?[\\d\\.]+)\\b");
    private static final Pattern REGEX_BYTERANGE = Pattern.compile(TAG_BYTERANGE
            + ":(\\d+(?:@\\d+)?)\\b");
    private static final Pattern REGEX_ATTR_BYTERANGE =
            Pattern.compile("BYTERANGE=\"(\\d+(?:@\\d+)?)\\b\"");
    private static final Pattern REGEX_METHOD =
            Pattern.compile(
                    "METHOD=("
                            + METHOD_NONE
                            + "|"
                            + METHOD_AES_128
                            + "|"
                            + METHOD_SAMPLE_AES
                            + "|"
                            + METHOD_SAMPLE_AES_CENC
                            + "|"
                            + METHOD_SAMPLE_AES_CTR
                            + ")"
                            + "\\s*(?:,|$)");
    private static final Pattern REGEX_KEYFORMAT = Pattern.compile("KEYFORMAT=\"(.+?)\"");
    private static final Pattern REGEX_KEYFORMATVERSIONS =
            Pattern.compile("KEYFORMATVERSIONS=\"(.+?)\"");
    private static final Pattern REGEX_URI = Pattern.compile("URI=\"(.+?)\"");
    private static final Pattern REGEX_IV = Pattern.compile("IV=([^,.*]+)");
    private static final Pattern REGEX_TYPE = Pattern.compile("TYPE=(" + TYPE_AUDIO + "|" + TYPE_VIDEO
            + "|" + TYPE_SUBTITLES + "|" + TYPE_CLOSED_CAPTIONS + ")");
    private static final Pattern REGEX_LANGUAGE = Pattern.compile("LANGUAGE=\"(.+?)\"");
    private static final Pattern REGEX_NAME = Pattern.compile("NAME=\"(.+?)\"");
    private static final Pattern REGEX_GROUP_ID = Pattern.compile("GROUP-ID=\"(.+?)\"");
    private static final Pattern REGEX_CHARACTERISTICS = Pattern.compile("CHARACTERISTICS=\"(.+?)\"");
    private static final Pattern REGEX_INSTREAM_ID =
            Pattern.compile("INSTREAM-ID=\"((?:CC|SERVICE)\\d+)\"");
    private static final Pattern REGEX_AUTOSELECT = compileBooleanAttrPattern("AUTOSELECT");
    private static final Pattern REGEX_DEFAULT = compileBooleanAttrPattern("DEFAULT");
    private static final Pattern REGEX_FORCED = compileBooleanAttrPattern("FORCED");
    private static final Pattern REGEX_VALUE = Pattern.compile("VALUE=\"(.+?)\"");
    private static final Pattern REGEX_IMPORT = Pattern.compile("IMPORT=\"(.+?)\"");
    private static final Pattern REGEX_VARIABLE_REFERENCE =
            Pattern.compile("\\{\\$([a-zA-Z0-9\\-_]+)\\}");

    private final CustomHlsMasterPlaylist masterPlaylist;

    /**
     * Creates an instance where media playlists are parsed without inheriting attributes from a
     * master playlist.
     */
    public CustomHlsPlaylistParser() {
        this(CustomHlsMasterPlaylist.EMPTY);
    }

    /**
     * Creates an instance where parsed media playlists inherit attributes from the given master
     * playlist.
     *
     * @param masterPlaylist The master playlist from which media playlists will inherit attributes.
     */
    public CustomHlsPlaylistParser(CustomHlsMasterPlaylist masterPlaylist) {
        this.masterPlaylist = masterPlaylist;
    }

    @OptIn(markerClass = UnstableApi.class)
    @Override
    public HlsPlaylist parse(Uri uri, InputStream inputStream) throws IOException {
        Log.i("MusicService", "Player : Parser...");
        BufferedReader reader = new BufferedReader(new InputStreamReader(inputStream));
        Queue<String> extraLines = new ArrayDeque<>();
        String line;
        try {
            if (!checkPlaylistHeader(reader)) {
                throw new UnrecognizedInputFormatException("Input does not start with the #EXTM3U header.",
                        uri);
            }
            while ((line = reader.readLine()) != null) {
                line = line.trim();
                Log.i("MusicService", "Player : Parser : Line 0: " + line);
                if (line.isEmpty()) {
                    // Do nothing.
                } else if (line.startsWith(TAG_STREAM_INF)) {
                    extraLines.add(line);
                    return parseMasterPlaylist(new CustomHlsPlaylistParser.LineIterator(extraLines, reader), uri.toString());
                } else if (line.startsWith(TAG_TARGET_DURATION)
                        || line.startsWith(TAG_MEDIA_SEQUENCE)
                        || line.startsWith(TAG_MEDIA_DURATION)
                        || line.startsWith(TAG_KEY)
                        || line.startsWith(TAG_BYTERANGE)
                        || line.equals(TAG_DISCONTINUITY)
                        || line.equals(TAG_DISCONTINUITY_SEQUENCE)
                        || line.equals(TAG_ENDLIST)) {
                    extraLines.add(line);
                    return parseMediaPlaylist(
                            masterPlaylist, new CustomHlsPlaylistParser.LineIterator(extraLines, reader), uri.toString());
                } else {
                    extraLines.add(line);
                }
            }
        } finally {
            Util.closeQuietly(reader);
        }
        throw ParserException.createForUnsupportedContainerFeature("Failed to parse the playlist, could not identify any tags.");
    }


    private static boolean checkPlaylistHeader(BufferedReader reader) throws IOException {
        int last = reader.read();
        if (last == 0xEF) {
            if (reader.read() != 0xBB || reader.read() != 0xBF) {
                return false;
            }
            // The playlist contains a Byte Order Mark, which gets discarded.
            last = reader.read();
        }
        last = skipIgnorableWhitespace(reader, true, last);
        int playlistHeaderLength = PLAYLIST_HEADER.length();
        for (int i = 0; i < playlistHeaderLength; i++) {
            if (last != PLAYLIST_HEADER.charAt(i)) {
                return false;
            }
            last = reader.read();
        }
        last = skipIgnorableWhitespace(reader, false, last);
        return Util.isLinebreak(last);
    }


    private static int skipIgnorableWhitespace(BufferedReader reader, boolean skipLinebreaks, int c)
            throws IOException {
        while (c != -1 && Character.isWhitespace(c) && (skipLinebreaks || !Util.isLinebreak(c))) {
            c = reader.read();
        }
        return c;
    }

    @UnstableApi
    private static HlsPlaylist parseMasterPlaylist(LineIterator iterator, String baseUri)
            throws IOException {
        HashMap<Uri, ArrayList<HlsTrackMetadataEntry.VariantInfo>> urlToVariantInfos = new HashMap<>();
        HashMap<String, String> variableDefinitions = new HashMap<>();
        ArrayList<CustomHlsMasterPlaylist.Variant> variants = new ArrayList<>();
        ArrayList<CustomHlsMasterPlaylist.Rendition> videos = new ArrayList<>();
        ArrayList<CustomHlsMasterPlaylist.Rendition> audios = new ArrayList<>();
        ArrayList<CustomHlsMasterPlaylist.Rendition> subtitles = new ArrayList<>();
        ArrayList<CustomHlsMasterPlaylist.Rendition> closedCaptions = new ArrayList<>();
        ArrayList<String> mediaTags = new ArrayList<>();
        ArrayList<DrmInitData> sessionKeyDrmInitData = new ArrayList<>();
        ArrayList<String> tags = new ArrayList<>();
        Format muxedAudioFormat = null;
        List<Format> muxedCaptionFormats = null;
        boolean noClosedCaptions = false;
        boolean hasIndependentSegmentsTag = false;

        String line;
        while (iterator.hasNext()) {
            line = iterator.next();

            Log.i("MusicService", "Player : Parser : Line 1 : " + line);

            if (line.startsWith(TAG_PREFIX)) {
                // We expose all tags through the playlist.
                tags.add(line);
            }

            if (line.startsWith(TAG_DEFINE)) {
                variableDefinitions.put(
                        /* key= */ parseStringAttr(line, REGEX_NAME, variableDefinitions),
                        /* value= */ parseStringAttr(line, REGEX_VALUE, variableDefinitions));
            } else if (line.equals(TAG_INDEPENDENT_SEGMENTS)) {
                hasIndependentSegmentsTag = true;
            } else if (line.startsWith(TAG_MEDIA)) {
                // Media tags are parsed at the end to include codec information from #EXT-X-STREAM-INF
                // tags.
                mediaTags.add(line);
            } else if (line.startsWith(TAG_SESSION_KEY)) {
                String keyFormat =
                        parseOptionalStringAttr(line, REGEX_KEYFORMAT, KEYFORMAT_IDENTITY, variableDefinitions);
                DrmInitData.SchemeData schemeData = parseDrmSchemeData(line, keyFormat, variableDefinitions);
                if (schemeData != null) {
                    String method = parseStringAttr(line, REGEX_METHOD, variableDefinitions);
                    String scheme = parseEncryptionScheme(method);
                    sessionKeyDrmInitData.add(new DrmInitData(scheme, schemeData));
                }
            } else if (line.startsWith(TAG_STREAM_INF)) {
                noClosedCaptions |= line.contains(ATTR_CLOSED_CAPTIONS_NONE);
                int bitrate = parseIntAttr(line, REGEX_BANDWIDTH);
                String averageBandwidthString =
                        parseOptionalStringAttr(line, REGEX_AVERAGE_BANDWIDTH, variableDefinitions);
                if (averageBandwidthString != null) {
                    // If available, the average bandwidth attribute is used as the variant's bitrate.
                    bitrate = Integer.parseInt(averageBandwidthString);
                }
                String codecs = parseOptionalStringAttr(line, REGEX_CODECS, variableDefinitions);
                String resolutionString =
                        parseOptionalStringAttr(line, REGEX_RESOLUTION, variableDefinitions);
                int width;
                int height;
                if (resolutionString != null) {
                    String[] widthAndHeight = resolutionString.split("x");
                    width = Integer.parseInt(widthAndHeight[0]);
                    height = Integer.parseInt(widthAndHeight[1]);
                    if (width <= 0 || height <= 0) {
                        // Resolution string is invalid.
                        width = Format.NO_VALUE;
                        height = Format.NO_VALUE;
                    }
                } else {
                    width = Format.NO_VALUE;
                    height = Format.NO_VALUE;
                }
                float frameRate = Format.NO_VALUE;
                String frameRateString =
                        parseOptionalStringAttr(line, REGEX_FRAME_RATE, variableDefinitions);
                if (frameRateString != null) {
                    frameRate = Float.parseFloat(frameRateString);
                }
                String videoGroupId = parseOptionalStringAttr(line, REGEX_VIDEO, variableDefinitions);
                String audioGroupId = parseOptionalStringAttr(line, REGEX_AUDIO, variableDefinitions);
                String subtitlesGroupId =
                        parseOptionalStringAttr(line, REGEX_SUBTITLES, variableDefinitions);
                String closedCaptionsGroupId =
                        parseOptionalStringAttr(line, REGEX_CLOSED_CAPTIONS, variableDefinitions);
                line =
                        replaceVariableReferences(
                                iterator.next(), variableDefinitions); // #EXT-X-STREAM-INF's URI.
                Uri uri = UriUtil.resolveToUri(baseUri, line);
                Format format =
                        new Format.Builder()
                                .setId(Integer.toString(variants.size()))
                                .setLabel(null)
                                .setSelectionFlags(0)
                                .setRoleFlags(0)
                                .setAverageBitrate(bitrate)
                                .setPeakBitrate(bitrate)
                                .setCodecs(codecs)
                                .setMetadata(null)
                                .setContainerMimeType(MimeTypes.APPLICATION_M3U8)
                                .setSampleMimeType(null)
                                .setInitializationData(null)
                                .setWidth(width)
                                .setHeight(height)
                                .setFrameRate(frameRate)
                                .build();
                CustomHlsMasterPlaylist.Variant variant =
                        new CustomHlsMasterPlaylist.Variant(
                                uri, format, videoGroupId, audioGroupId, subtitlesGroupId, closedCaptionsGroupId);
                variants.add(variant);
                ArrayList<HlsTrackMetadataEntry.VariantInfo> variantInfosForUrl = urlToVariantInfos.get(uri);
                if (variantInfosForUrl == null) {
                    variantInfosForUrl = new ArrayList<>();
                    urlToVariantInfos.put(uri, variantInfosForUrl);
                }
                variantInfosForUrl.add(new HlsTrackMetadataEntry.VariantInfo(bitrate, bitrate, videoGroupId, audioGroupId, subtitlesGroupId, closedCaptionsGroupId));
            }
        }

        // TODO: Don't deduplicate variants by URL.
        ArrayList<CustomHlsMasterPlaylist.Variant> deduplicatedVariants = new ArrayList<>();
        HashSet<Uri> urlsInDeduplicatedVariants = new HashSet<>();
        for (int i = 0; i < variants.size(); i++) {
            CustomHlsMasterPlaylist.Variant variant = variants.get(i);
            if (urlsInDeduplicatedVariants.add(variant.url)) {
                Assertions.checkState(variant.format.metadata == null);
                HlsTrackMetadataEntry hlsMetadataEntry =
                        new HlsTrackMetadataEntry(
                                /* groupId= */ null, /* name= */ null, urlToVariantInfos.get(variant.url));
                deduplicatedVariants.add(
                        variant.copyWithFormat(
                                variant.format.buildUpon().setMetadata((new Metadata(hlsMetadataEntry))).build()));
            }
        }

        for (int i = 0; i < mediaTags.size(); i++) {
            line = mediaTags.get(i);
            String groupId = parseStringAttr(line, REGEX_GROUP_ID, variableDefinitions);
            String name = parseStringAttr(line, REGEX_NAME, variableDefinitions);
            String referenceUri = parseOptionalStringAttr(line, REGEX_URI, variableDefinitions);
            Uri uri = referenceUri == null ? null : UriUtil.resolveToUri(baseUri, referenceUri);
            String language = parseOptionalStringAttr(line, REGEX_LANGUAGE, variableDefinitions);
            @C.SelectionFlags int selectionFlags = parseSelectionFlags(line);
            @C.RoleFlags int roleFlags = parseRoleFlags(line, variableDefinitions);
            String formatId = groupId + ":" + name;
            Format format;
            Metadata metadata =
                    new Metadata(new HlsTrackMetadataEntry(groupId, name, new ArrayList<HlsTrackMetadataEntry.VariantInfo>()));
            switch (parseStringAttr(line, REGEX_TYPE, variableDefinitions)) {
                case TYPE_VIDEO:
                    CustomHlsMasterPlaylist.Variant variant = getVariantWithVideoGroup(variants, groupId);
                    String codecs = null;
                    int width = Format.NO_VALUE;
                    int height = Format.NO_VALUE;
                    float frameRate = Format.NO_VALUE;
                    if (variant != null) {
                        Format variantFormat = variant.format;
                        codecs = Util.getCodecsOfType(variantFormat.codecs, C.TRACK_TYPE_VIDEO);
                        width = variantFormat.width;
                        height = variantFormat.height;
                        frameRate = variantFormat.frameRate;
                    }
                    String sampleMimeType = codecs != null ? MimeTypes.getMediaMimeType(codecs) : null;
                    format =
                            new Format.Builder()
                                    .setId(formatId)
                                    .setLabel(name)
                                    .setSelectionFlags(selectionFlags)
                                    .setRoleFlags(roleFlags)
                                    .setAverageBitrate(Format.NO_VALUE)
                                    .setPeakBitrate(Format.NO_VALUE)
                                    .setCodecs(codecs)
                                    .setMetadata(metadata)
                                    .setContainerMimeType(MimeTypes.APPLICATION_M3U8)
                                    .setSampleMimeType(sampleMimeType)
                                    .setInitializationData(null)
                                    .setWidth(width)
                                    .setHeight(height)
                                    .setFrameRate(frameRate)
                                    .build();
                    //.copyWithMetadata(metadata);
                    if (uri == null) {
                        // TODO: Remove this case and add a Rendition with a null uri to videos.
                    } else {
                        videos.add(new CustomHlsMasterPlaylist.Rendition(uri, format, groupId, name));
                    }
                    break;
                case TYPE_AUDIO:
                    variant = getVariantWithAudioGroup(variants, groupId);
                    codecs =
                            variant != null
                                    ? Util.getCodecsOfType(variant.format.codecs, C.TRACK_TYPE_AUDIO)
                                    : null;
                    sampleMimeType = codecs != null ? MimeTypes.getMediaMimeType(codecs) : null;
                    int channelCount = parseChannelsAttribute(line, variableDefinitions);
                    format = new Format.Builder()
                            .setId(formatId)
                            .setLabel(name)
                            .setLanguage(language)
                            .setSelectionFlags(selectionFlags)
                            .setRoleFlags(roleFlags)
                            .setAverageBitrate(Format.NO_VALUE)
                            .setPeakBitrate(Format.NO_VALUE)
                            .setCodecs(codecs)
                            .setMetadata(metadata)
                            .setContainerMimeType(MimeTypes.APPLICATION_M3U8)
                            .setSampleMimeType(sampleMimeType)
                            .setInitializationData(null)
                            .setChannelCount(channelCount)
                            .setSampleRate(Format.NO_VALUE)
                            .build();
                    if (uri == null) {
                        // TODO: Remove muxedAudioFormat and add a Rendition with a null uri to audios.
                        muxedAudioFormat = format;
                    } else {
                        audios.add(new CustomHlsMasterPlaylist.Rendition(uri, format.buildUpon().setMetadata(metadata).build(), groupId, name));
                    }
                    break;
                case TYPE_SUBTITLES:
                    format =
                            new Format.Builder()
                                    .setId(formatId)
                                    .setLabel(name)
                                    .setLanguage(language)
                                    .setSelectionFlags(selectionFlags)
                                    .setRoleFlags(roleFlags)
                                    .setAverageBitrate(Format.NO_VALUE)
                                    .setPeakBitrate(Format.NO_VALUE)
                                    .setCodecs(null)
                                    .setContainerMimeType(MimeTypes.APPLICATION_M3U8)
                                    .setSampleMimeType(MimeTypes.TEXT_VTT)
                                    .setMetadata(metadata)
                                    .build();
                    subtitles.add(new CustomHlsMasterPlaylist.Rendition(uri, format, groupId, name));
                    break;
                case TYPE_CLOSED_CAPTIONS:
                    String instreamId = parseStringAttr(line, REGEX_INSTREAM_ID, variableDefinitions);
                    String mimeType;
                    int accessibilityChannel;
                    if (instreamId.startsWith("CC")) {
                        mimeType = MimeTypes.APPLICATION_CEA608;
                        accessibilityChannel = Integer.parseInt(instreamId.substring(2));
                    } else /* starts with SERVICE */ {
                        mimeType = MimeTypes.APPLICATION_CEA708;
                        accessibilityChannel = Integer.parseInt(instreamId.substring(7));
                    }
                    if (muxedCaptionFormats == null) {
                        muxedCaptionFormats = new ArrayList<>();
                    }
                    muxedCaptionFormats.add(
                            new Format.Builder()
                                    .setId(formatId)
                                    .setLabel(name)
                                    .setLanguage(language)
                                    .setSelectionFlags(selectionFlags)
                                    .setRoleFlags(roleFlags)
                                    .setAverageBitrate(Format.NO_VALUE)
                                    .setPeakBitrate(Format.NO_VALUE)
                                    .setCodecs(null)
                                    .setContainerMimeType(null)
                                    .setSampleMimeType(mimeType)
                                    .setAccessibilityChannel(accessibilityChannel)
                                    .build());

                    // TODO: Remove muxedCaptionFormats and add a Rendition with a null uri to closedCaptions.
                    break;
                default:
                    // Do nothing.
                    break;
            }
        }

        if (noClosedCaptions) {
            muxedCaptionFormats = Collections.emptyList();
        }

        return new CustomHlsMasterPlaylist(
                URLEncoder.encode(baseUri, "utf-8"),
                tags,
                deduplicatedVariants,
                videos,
                audios,
                subtitles,
                closedCaptions,
                muxedAudioFormat,
                muxedCaptionFormats,
                hasIndependentSegmentsTag,
                variableDefinitions,
                sessionKeyDrmInitData);
    }

    private static CustomHlsMasterPlaylist.Variant getVariantWithAudioGroup(ArrayList<CustomHlsMasterPlaylist.Variant> variants, String groupId) {
        for (int i = 0; i < variants.size(); i++) {
            CustomHlsMasterPlaylist.Variant variant = variants.get(i);
            if (groupId.equals(variant.audioGroupId)) {
                return variant;
            }
        }
        return null;
    }

    private static CustomHlsMasterPlaylist.Variant getVariantWithVideoGroup(ArrayList<CustomHlsMasterPlaylist.Variant> variants, String groupId) {
        for (int i = 0; i < variants.size(); i++) {
            CustomHlsMasterPlaylist.Variant variant = variants.get(i);
            if (groupId.equals(variant.videoGroupId)) {
                return variant;
            }
        }
        return null;
    }

    private static HlsMediaPlaylist parseMediaPlaylist(
            CustomHlsMasterPlaylist masterPlaylist, CustomHlsPlaylistParser.LineIterator iterator, String baseUri) throws IOException {
        @HlsMediaPlaylist.PlaylistType int playlistType = HlsMediaPlaylist.PLAYLIST_TYPE_UNKNOWN;
        long startOffsetUs = C.TIME_UNSET;
        long mediaSequence = 0;
        int version = 1; // Default version == 1.
        long targetDurationUs = C.TIME_UNSET;
        boolean hasIndependentSegmentsTag = masterPlaylist.hasIndependentSegments;
        boolean hasEndTag = false;
        HlsMediaPlaylist.Segment initializationSegment = null;
        HashMap<String, String> variableDefinitions = new HashMap<>();
        List<HlsMediaPlaylist.Segment> segments = new ArrayList<>();
        List<String> tags = new ArrayList<>();

        long segmentDurationUs = 0;
        String segmentTitle = "";
        boolean hasDiscontinuitySequence = false;
        int playlistDiscontinuitySequence = 0;
        int relativeDiscontinuitySequence = 0;
        long playlistStartTimeUs = 0;
        long segmentStartTimeUs = 0;
        long segmentByteRangeOffset = 0;
        long segmentByteRangeLength = C.LENGTH_UNSET;
        long segmentMediaSequence = 0;
        boolean hasGapTag = false;

        DrmInitData playlistProtectionSchemes = null;
        String fullSegmentEncryptionKeyUri = null;
        String fullSegmentEncryptionIV = null;
        TreeMap<String, DrmInitData.SchemeData> currentSchemeDatas = new TreeMap<>();
        String encryptionScheme = null;
        DrmInitData cachedDrmInitData = null;
        List<HlsMediaPlaylist.Part> trailingParts = new ArrayList<>();
        Map<Uri, HlsMediaPlaylist.RenditionReport> renditionReports = new HashMap<>();
        HlsMediaPlaylist.ServerControl serverControl = new HlsMediaPlaylist.ServerControl(0, false, 0, 0, false);
        List<HlsMediaPlaylist.Part> updatedParts = new ArrayList<>();

        String line;
        while (iterator.hasNext()) {
            line = iterator.next();

            Log.i("MusicService", "Player : Parser : Line 2: " + line);

            if (line.startsWith(TAG_PREFIX)) {
                // We expose all tags through the playlist.
                tags.add(line);
            }

            if (line.startsWith(TAG_PLAYLIST_TYPE)) {
                String playlistTypeString = parseStringAttr(line, REGEX_PLAYLIST_TYPE, variableDefinitions);
                if ("VOD".equals(playlistTypeString)) {
                    playlistType = HlsMediaPlaylist.PLAYLIST_TYPE_VOD;
                } else if ("EVENT".equals(playlistTypeString)) {
                    playlistType = HlsMediaPlaylist.PLAYLIST_TYPE_EVENT;
                }
            } else if (line.startsWith(TAG_START)) {
                startOffsetUs = (long) (parseDoubleAttr(line, REGEX_TIME_OFFSET) * C.MICROS_PER_SECOND);
            } else if (line.startsWith(TAG_INIT_SEGMENT)) {
                String uri = parseStringAttr(line, REGEX_URI, variableDefinitions);
                String byteRange = parseOptionalStringAttr(line, REGEX_ATTR_BYTERANGE, variableDefinitions);
                if (byteRange != null) {
                    String[] splitByteRange = byteRange.split("@");
                    segmentByteRangeLength = Long.parseLong(splitByteRange[0]);
                    if (splitByteRange.length > 1) {
                        segmentByteRangeOffset = Long.parseLong(splitByteRange[1]);
                    }
                }
                if (fullSegmentEncryptionKeyUri != null && fullSegmentEncryptionIV == null) {
                    // See RFC 8216, Section 4.3.2.5.
                    throw ParserException.createForUnsupportedContainerFeature(
                            "The encryption IV attribute must be present when an initialization segment is "
                                    + "encrypted with METHOD=AES-128.");
                }
                initializationSegment =
                        new HlsMediaPlaylist.Segment(
                                uri,
                                segmentByteRangeOffset,
                                segmentByteRangeLength,
                                fullSegmentEncryptionKeyUri,
                                fullSegmentEncryptionIV);
                segmentByteRangeOffset = 0;
                segmentByteRangeLength = C.LENGTH_UNSET;
            } else if (line.startsWith(TAG_TARGET_DURATION)) {
                targetDurationUs = parseIntAttr(line, REGEX_TARGET_DURATION) * C.MICROS_PER_SECOND;
            } else if (line.startsWith(TAG_MEDIA_SEQUENCE)) {
                mediaSequence = parseLongAttr(line, REGEX_MEDIA_SEQUENCE);
                segmentMediaSequence = mediaSequence;
            } else if (line.startsWith(TAG_VERSION)) {
                version = parseIntAttr(line, REGEX_VERSION);
            } else if (line.startsWith(TAG_DEFINE)) {
                String importName = parseOptionalStringAttr(line, REGEX_IMPORT, variableDefinitions);
                if (importName != null) {
                    String value = masterPlaylist.variableDefinitions.get(importName);
                    if (value != null) {
                        variableDefinitions.put(importName, value);
                    } else {
                        // The master playlist does not declare the imported variable. Ignore.
                    }
                } else {
                    variableDefinitions.put(
                            parseStringAttr(line, REGEX_NAME, variableDefinitions),
                            parseStringAttr(line, REGEX_VALUE, variableDefinitions));
                }
            } else if (line.startsWith(TAG_MEDIA_DURATION)) {
                segmentDurationUs =
                        (long) (parseDoubleAttr(line, REGEX_MEDIA_DURATION) * C.MICROS_PER_SECOND);
                segmentTitle = parseOptionalStringAttr(line, REGEX_MEDIA_TITLE, "", variableDefinitions);
            } else if (line.startsWith(TAG_KEY)) {
                String method = parseStringAttr(line, REGEX_METHOD, variableDefinitions);
                String keyFormat =
                        parseOptionalStringAttr(line, REGEX_KEYFORMAT, KEYFORMAT_IDENTITY, variableDefinitions);
                fullSegmentEncryptionKeyUri = null;
                fullSegmentEncryptionIV = null;
                if (METHOD_NONE.equals(method)) {
                    currentSchemeDatas.clear();
                    cachedDrmInitData = null;
                } else /* !METHOD_NONE.equals(method) */ {
                    fullSegmentEncryptionIV = parseOptionalStringAttr(line, REGEX_IV, variableDefinitions);
                    if (KEYFORMAT_IDENTITY.equals(keyFormat)) {
                        if (METHOD_AES_128.equals(method)) {
                            // The segment is fully encrypted using an identity key.
                            fullSegmentEncryptionKeyUri = parseStringAttr(line, REGEX_URI, variableDefinitions);
                        } else {
                            // Do nothing. Samples are encrypted using an identity key, but this is not supported.
                            // Hopefully, a traditional DRM alternative is also provided.
                        }
                    } else {
                        if (encryptionScheme == null) {
                            encryptionScheme = parseEncryptionScheme(method);
                        }
                        DrmInitData.SchemeData schemeData = parseDrmSchemeData(line, keyFormat, variableDefinitions);
                        if (schemeData != null) {
                            cachedDrmInitData = null;
                            currentSchemeDatas.put(keyFormat, schemeData);
                        }
                    }
                }
            } else if (line.startsWith(TAG_BYTERANGE)) {
                String byteRange = parseStringAttr(line, REGEX_BYTERANGE, variableDefinitions);
                String[] splitByteRange = byteRange.split("@");
                segmentByteRangeLength = Long.parseLong(splitByteRange[0]);
                if (splitByteRange.length > 1) {
                    segmentByteRangeOffset = Long.parseLong(splitByteRange[1]);
                }
            } else if (line.startsWith(TAG_DISCONTINUITY_SEQUENCE)) {
                hasDiscontinuitySequence = true;
                playlistDiscontinuitySequence = Integer.parseInt(line.substring(line.indexOf(':') + 1));
            } else if (line.equals(TAG_DISCONTINUITY)) {
                relativeDiscontinuitySequence++;
            } else if (line.startsWith(TAG_PROGRAM_DATE_TIME)) {
                if (playlistStartTimeUs == 0) {
                    long programDatetimeUs =
                            Util.msToUs(Util.parseXsDateTime(line.substring(line.indexOf(':') + 1)));
                    playlistStartTimeUs = programDatetimeUs - segmentStartTimeUs;
                }
            } else if (line.equals(TAG_GAP)) {
                hasGapTag = true;
            } else if (line.equals(TAG_INDEPENDENT_SEGMENTS)) {
                hasIndependentSegmentsTag = true;
            } else if (line.equals(TAG_ENDLIST)) {
                hasEndTag = true;
            } else if (!line.startsWith("#")) {
                String segmentEncryptionIV;
                if (fullSegmentEncryptionKeyUri == null) {
                    segmentEncryptionIV = null;
                } else if (fullSegmentEncryptionIV != null) {
                    segmentEncryptionIV = fullSegmentEncryptionIV;
                } else {
                    segmentEncryptionIV = Long.toHexString(segmentMediaSequence);
                }

                segmentMediaSequence++;
                if (segmentByteRangeLength == C.LENGTH_UNSET) {
                    segmentByteRangeOffset = 0;
                }

                if (cachedDrmInitData == null && !currentSchemeDatas.isEmpty()) {
                    DrmInitData.SchemeData[] schemeDatas = currentSchemeDatas.values().toArray(new DrmInitData.SchemeData[0]);
                    cachedDrmInitData = new DrmInitData(encryptionScheme, schemeDatas);
                    if (playlistProtectionSchemes == null) {
                        DrmInitData.SchemeData[] playlistSchemeDatas = new DrmInitData.SchemeData[schemeDatas.length];
                        for (int i = 0; i < schemeDatas.length; i++) {
                            playlistSchemeDatas[i] = schemeDatas[i].copyWithData(null);
                        }
                        playlistProtectionSchemes = new DrmInitData(encryptionScheme, playlistSchemeDatas);
                    }
                }

                line = URLEncoder.encode(line, "utf-8");

                Log.i("MediaService", "Player : Parser : Line 3: " + replaceVariableReferences(line, variableDefinitions));

                segments.add(
                        new HlsMediaPlaylist.Segment(
                                replaceVariableReferences(line, variableDefinitions),
                                initializationSegment,
                                segmentTitle,
                                segmentDurationUs,
                                relativeDiscontinuitySequence,
                                segmentStartTimeUs,
                                cachedDrmInitData,
                                fullSegmentEncryptionKeyUri,
                                segmentEncryptionIV,
                                segmentByteRangeOffset,
                                segmentByteRangeLength,
                                hasGapTag,
                                updatedParts));
                segmentStartTimeUs += segmentDurationUs;
                segmentDurationUs = 0;
                segmentTitle = "";
                if (segmentByteRangeLength != C.LENGTH_UNSET) {
                    segmentByteRangeOffset += segmentByteRangeLength;
                }
                segmentByteRangeLength = C.LENGTH_UNSET;
                hasGapTag = false;
            }
        }

                return new HlsMediaPlaylist(
                playlistType,
                baseUri,
                tags,
                startOffsetUs,
                false,
                playlistStartTimeUs,
                hasDiscontinuitySequence,
                playlistDiscontinuitySequence,
                mediaSequence,
                version,
                targetDurationUs,
                targetDurationUs,
                hasIndependentSegmentsTag,
                hasEndTag,
                /* hasProgramDateTime= */ playlistStartTimeUs != 0,
                playlistProtectionSchemes,
                segments, trailingParts, serverControl, renditionReports
//                /* interstitial= */ null
                );
    }

    @C.SelectionFlags
    private static int parseSelectionFlags(String line) {
        int flags = 0;
        if (parseOptionalBooleanAttribute(line, REGEX_DEFAULT, false)) {
            flags |= C.SELECTION_FLAG_DEFAULT;
        }
        if (parseOptionalBooleanAttribute(line, REGEX_FORCED, false)) {
            flags |= C.SELECTION_FLAG_FORCED;
        }
        if (parseOptionalBooleanAttribute(line, REGEX_AUTOSELECT, false)) {
            flags |= C.SELECTION_FLAG_AUTOSELECT;
        }
        return flags;
    }

    @C.RoleFlags

    private static int parseRoleFlags(String line, Map<String, String> variableDefinitions) {
        String concatenatedCharacteristics =
                parseOptionalStringAttr(line, REGEX_CHARACTERISTICS, variableDefinitions);
        if (TextUtils.isEmpty(concatenatedCharacteristics)) {
            return 0;
        }
        String[] characteristics = Util.split(concatenatedCharacteristics, ",");
        @C.RoleFlags int roleFlags = 0;
        if (Util.contains(characteristics, "public.accessibility.describes-video")) {
            roleFlags |= C.ROLE_FLAG_DESCRIBES_VIDEO;
        }
        if (Util.contains(characteristics, "public.accessibility.transcribes-spoken-dialog")) {
            roleFlags |= C.ROLE_FLAG_TRANSCRIBES_DIALOG;
        }
        if (Util.contains(characteristics, "public.accessibility.describes-music-and-sound")) {
            roleFlags |= C.ROLE_FLAG_DESCRIBES_MUSIC_AND_SOUND;
        }
        if (Util.contains(characteristics, "public.easy-to-read")) {
            roleFlags |= C.ROLE_FLAG_EASY_TO_READ;
        }
        return roleFlags;
    }


    private static int parseChannelsAttribute(String line, Map<String, String> variableDefinitions) {
        String channelsString = parseOptionalStringAttr(line, REGEX_CHANNELS, variableDefinitions);
        return channelsString != null
                ? Integer.parseInt(Util.splitAtFirst(channelsString, "/")[0])
                : Format.NO_VALUE;
    }

    @Nullable

    private static DrmInitData.SchemeData parseDrmSchemeData(
            String line, String keyFormat, Map<String, String> variableDefinitions)
            throws ParserException {
        String keyFormatVersions =
                parseOptionalStringAttr(line, REGEX_KEYFORMATVERSIONS, "1", variableDefinitions);
        if (KEYFORMAT_WIDEVINE_PSSH_BINARY.equals(keyFormat)) {
            String uriString = parseStringAttr(line, REGEX_URI, variableDefinitions);
            return new DrmInitData.SchemeData(
                    C.WIDEVINE_UUID,
                    MimeTypes.VIDEO_MP4,
                    Base64.decode(uriString.substring(uriString.indexOf(',')), Base64.DEFAULT));
        } else if (KEYFORMAT_WIDEVINE_PSSH_JSON.equals(keyFormat)) {
            return new DrmInitData.SchemeData(C.WIDEVINE_UUID, "hls", Util.getUtf8Bytes(line));
        } else if (KEYFORMAT_PLAYREADY.equals(keyFormat) && "1".equals(keyFormatVersions)) {
            String uriString = parseStringAttr(line, REGEX_URI, variableDefinitions);
            byte[] data = Base64.decode(uriString.substring(uriString.indexOf(',')), Base64.DEFAULT);
            byte[] psshData = PsshAtomUtil.buildPsshAtom(C.PLAYREADY_UUID, data);
            return new DrmInitData.SchemeData(C.PLAYREADY_UUID, MimeTypes.VIDEO_MP4, psshData);
        }
        return null;
    }


    private static String parseEncryptionScheme(String method) {
        return METHOD_SAMPLE_AES_CENC.equals(method) || METHOD_SAMPLE_AES_CTR.equals(method)
                ? C.CENC_TYPE_cenc
                : C.CENC_TYPE_cbcs;
    }


    private static int parseIntAttr(String line, Pattern pattern) throws ParserException {
        return Integer.parseInt(parseStringAttr(line, pattern, new HashMap<String, String>()));
    }


    private static long parseLongAttr(String line, Pattern pattern) throws ParserException {
        return Long.parseLong(parseStringAttr(line, pattern, new HashMap<String, String>()));
    }


    private static double parseDoubleAttr(String line, Pattern pattern) throws ParserException {
        return Double.parseDouble(parseStringAttr(line, pattern, new HashMap<String, String>()));
    }


    private static String parseStringAttr(
            String line, Pattern pattern, Map<String, String> variableDefinitions)
            throws ParserException {
        String value = parseOptionalStringAttr(line, pattern, variableDefinitions);
        if (value != null) {
            return value;
        } else {
            throw ParserException.createForUnsupportedContainerFeature("Couldn't match " + pattern.pattern() + " in " + line);
        }
    }

    private static @Nullable
    String parseOptionalStringAttr(
            String line, Pattern pattern, Map<String, String> variableDefinitions) {
        return parseOptionalStringAttr(line, pattern, null, variableDefinitions);
    }

    private static String parseOptionalStringAttr(
            String line,
            Pattern pattern,
            String defaultValue,
            Map<String, String> variableDefinitions) {
        Matcher matcher = pattern.matcher(line);
        String value = matcher.find() ? matcher.group(1) : defaultValue;
        return variableDefinitions.isEmpty() || value == null
                ? value
                : replaceVariableReferences(value, variableDefinitions);
    }

    private static String replaceVariableReferences(
            String string, Map<String, String> variableDefinitions) {
        Matcher matcher = REGEX_VARIABLE_REFERENCE.matcher(string);
        // TODO: Replace StringBuffer with StringBuilder once Java 9 is available.
        StringBuffer stringWithReplacements = new StringBuffer();
        while (matcher.find()) {
            String groupName = matcher.group(1);
            if (variableDefinitions.containsKey(groupName)) {
                matcher.appendReplacement(
                        stringWithReplacements, Matcher.quoteReplacement(variableDefinitions.get(groupName)));
            } else {
                // The variable is not defined. The value is ignored.
            }
        }
        matcher.appendTail(stringWithReplacements);
        return stringWithReplacements.toString();
    }

    private static boolean parseOptionalBooleanAttribute(
            String line, Pattern pattern, boolean defaultValue) {
        Matcher matcher = pattern.matcher(line);
        if (matcher.find()) {
            return matcher.group(1).equals(BOOLEAN_TRUE);
        }
        return defaultValue;
    }

    private static Pattern compileBooleanAttrPattern(String attribute) {
        return Pattern.compile(attribute + "=(" + BOOLEAN_FALSE + "|" + BOOLEAN_TRUE + ")");
    }

    private static class LineIterator {

        private final BufferedReader reader;
        private final Queue<String> extraLines;

        private String next;

        public LineIterator(Queue<String> extraLines, BufferedReader reader) {
            this.extraLines = extraLines;
            this.reader = reader;
        }

        public boolean hasNext() throws IOException {
            if (next != null) {
                return true;
            }
            if (!extraLines.isEmpty()) {
                next = extraLines.poll();
                return true;
            }
            while ((next = reader.readLine()) != null) {
                next = next.trim();
                if (!next.isEmpty()) {
                    return true;
                }
            }
            return false;
        }

        public String next() throws IOException {
            String result = null;
            if (hasNext()) {
                result = next;
                next = null;
            }
            return result;
        }

    }

}