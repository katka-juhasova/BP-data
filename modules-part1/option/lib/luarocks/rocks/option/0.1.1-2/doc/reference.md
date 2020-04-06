
# Option reference

* `Option(val)` -> _Option_ - Returns a new Option table. All non-nil objects are considered **Some**, and nil is considered **None**.
* `Option:is_some()` -> _bool_ - Returns true if **Some**.
* `Option:is_none()` -> _bool_ - Returns true if **None**.
* `Option:expect(exception)` -> _val_ - Unwraps if it is **Some**. If it is **None**, then it throws an error with the message `exception`.
* `Option:unwrap()` -> _val_ or `nil` - Unwraps, even if **None**.
* `Option:unwrap_or(default_value)` -> _val_ - Unwraps if it is **Some**, else returns `default_value`.
* `Option:unwrap_or_else(default_func)` -> _val_ - Unwraps if it is **Some**, else returns `default_func()`.
* `Option:fallback(alternate_value)` -> _Option_ - Returns itself if **Some**, else returns `Object(alternate_value)`.
* `Option:match(is_some_func, is_none_func)` -> _val_ - Returns `is_some_func(val)` or `is_none_func()` if it is **Some** or **None**, respectively.

