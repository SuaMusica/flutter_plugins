// IMediaService.aidl
package smplayer;

interface IMediaService {
    void prepare(String cookie, String name, String author, String url, String coverUrl);
    void play();
    void pause();
    void seek(long position);
    void stop();
    void release();
    void sendNotification();
    void removeNotification();
    void next();
    void previous();
    long getDuration();
    long getCurrentPosition();
    void setReleaseMode(int releaseMode);
    int getReleaseMode();
}
