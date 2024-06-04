import { useState } from "react";

export default function useForm(validate: (value: string) => boolean) {
  const [value, setValue] = useState<string>("");
  const [valid, setValid] = useState<boolean>(false);
  const [touched, setTouched] = useState<boolean>(false);
  const [dirty, setDirty] = useState<boolean>(false);

  const onChange = (event: React.ChangeEvent<HTMLInputElement>) => {
    const { value } = event.target;
    setValid(validate(value));
    setValue(value);
    setDirty(true);
  };

  const onBlur = (_: React.FocusEvent<HTMLInputElement>) => {
    setTouched(true);
  };

  return {
    value,
    onChange,
    onBlur,
    valid,
    touched,
    dirty,
  };
}
