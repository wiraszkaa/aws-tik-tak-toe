import { useReducer, useCallback } from "react";

interface HttpState<T = any> {
  status: string;
  data?: T;
  error?: string;
}

const httpReducer = (state: HttpState, action: any) => {
  if (action.type === "SEND") {
    return {
      status: "loading",
    };
  }

  if (action.type === "SUCCESS") {
    return {
      data: action.responseData,
      status: "success",
    };
  }

  if (action.type === "ERROR") {
    return {
      error: action.errorMessage,
      status: "error",
    };
  }

  if (action.type === "CLEAR") {
    return {
      status: "pending",
    };
  }

  return state;
};

export default function useHttp<T>(
  requestFunction: (data?: any) => Promise<T>,
  startWithLoading = false
) {
  const [httpState, dispatch] = useReducer<
    (state: HttpState<T>, action: any) => HttpState<T>
  >(httpReducer, {
    status: startWithLoading ? "loading" : "pending",
  });

  const sendRequest = useCallback(
    async (requestData?: any) => {
      dispatch({ type: "SEND" });
      try {
        const responseData = await requestFunction(requestData);
        dispatch({ type: "SUCCESS", responseData });
      } catch (error: any) {
        dispatch({
          type: "ERROR",
          errorMessage: error.message || "Something went wrong!",
        });
      }
    },
    [requestFunction]
  );

  const clear = useCallback(() => {
    dispatch({ type: "CLEAR" });
  }, []);

  return {
    sendRequest,
    clear,
    ...httpState,
  };
}
