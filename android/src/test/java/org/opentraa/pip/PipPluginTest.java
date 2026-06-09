package org.opentraa.pip;

import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertNull;

import android.graphics.Rect;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.robolectric.RobolectricTestRunner;

@RunWith(RobolectricTestRunner.class)
public class PipPluginTest {
  @Test
  public void parsePositiveIntReturnsNullForInvalidValues() {
    assertEquals(Integer.valueOf(16), PipPlugin.parsePositiveInt(16));
    assertNull(PipPlugin.parsePositiveInt(0));
    assertNull(PipPlugin.parsePositiveInt(-1));
    assertNull(PipPlugin.parsePositiveInt("16"));
    assertNull(PipPlugin.parsePositiveInt(null));
  }

  @Test
  public void parseSourceRectRejectsPartialOrInvalidRects() {
    assertNull(PipPlugin.parseSourceRect(0, 0, 0, 10));
    assertNull(PipPlugin.parseSourceRect(0, null, 10, 10));

    Rect emptyRect = PipPlugin.parseSourceRect(0, 0, 0, 0);
    assertEquals(0, emptyRect.left);
    assertEquals(0, emptyRect.top);
    assertEquals(0, emptyRect.right);
    assertEquals(0, emptyRect.bottom);

    Rect rect = PipPlugin.parseSourceRect(0, 0, 10, 10);
    assertEquals(0, rect.left);
    assertEquals(0, rect.top);
    assertEquals(10, rect.right);
    assertEquals(10, rect.bottom);
  }
}
