package org.opentraa.pip;

import android.content.res.Configuration;
import android.os.Build;
import androidx.annotation.RequiresApi;
import io.flutter.embedding.android.FlutterActivity;

@RequiresApi(Build.VERSION_CODES.O)
public class PipActivity extends FlutterActivity {
  public interface PipActivityListener {
    void onPictureInPictureModeChanged(boolean isInPictureInPictureMode,
                                       Configuration newConfig);

    boolean onPictureInPictureRequested();

    void onUserLeaveHint();
  }

  private PipActivityListener mListener;

  public void setPipActivityListener(PipActivityListener listener) {
    mListener = listener;
  }

  // only available in API level 26 and above
  @RequiresApi(26)
  @Override
  public void onPictureInPictureModeChanged(boolean isInPictureInPictureMode,
                                            Configuration newConfig) {
    super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig);
    if (mListener != null) {
      mListener.onPictureInPictureModeChanged(isInPictureInPictureMode,
                                              newConfig);
    }
  }

  // only available in API level 30 and above
  @RequiresApi(30)
  @Override
  public boolean onPictureInPictureRequested() {
    if (mListener != null) {
      return mListener.onPictureInPictureRequested();
    }
    return super.onPictureInPictureRequested();
  }

  @Override
  public void onUserLeaveHint() {
    super.onUserLeaveHint();
    if (mListener != null) {
      mListener.onUserLeaveHint();
    }
  }
}
