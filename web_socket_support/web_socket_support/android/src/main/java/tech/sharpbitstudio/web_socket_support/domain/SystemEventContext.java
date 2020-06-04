package tech.sharpbitstudio.web_socket_support.domain;

import android.util.ArrayMap;
import java.io.Serializable;
import java.util.Map;
import lombok.Builder;
import lombok.Value;

@Value
@Builder
public class SystemEventContext implements Serializable {

  int closeCode;
  String closeReason;

  public Map<String, Object> toMap() {
    Map<String, Object> result = new ArrayMap<>();
    result.put("code", closeCode);
    result.put("reason", closeReason);
    return result;
  }
}
