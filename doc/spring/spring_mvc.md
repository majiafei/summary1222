# 处理@RequestMapping注解

RequestMappingHandlerMapping专门处理RequestMapping注解的。

## RequestMappingHandlerMapping

### 类图

![image-20210205115029853](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210205115029853.png)



### afterPropertiesSet

在实例化之后会调用这个方法。

```java
@Override
@SuppressWarnings("deprecation")
public void afterPropertiesSet() {
   this.config = new RequestMappingInfo.BuilderConfiguration();
   this.config.setUrlPathHelper(getUrlPathHelper());
   this.config.setPathMatcher(getPathMatcher());
   this.config.setSuffixPatternMatch(useSuffixPatternMatch());
   this.config.setTrailingSlashMatch(useTrailingSlashMatch());
   this.config.setRegisteredSuffixPatternMatch(useRegisteredSuffixPatternMatch());
   this.config.setContentNegotiationManager(getContentNegotiationManager());

   super.afterPropertiesSet();
}
```

### 初始化HandlerMethod

```java
/**
 * Scan beans in the ApplicationContext, detect and register handler methods.
 * @see #getCandidateBeanNames()
 * @see #processCandidateBean
 * @see #handlerMethodsInitialized
 */
protected void initHandlerMethods() {
   for (String beanName : getCandidateBeanNames()) {
      if (!beanName.startsWith(SCOPED_TARGET_NAME_PREFIX)) {
          // 处理没有bean中的方法,带有RequestMapping注解的，将其属性值封装到RequestMappingInfo中。
         processCandidateBean(beanName);
      }
   }
   handlerMethodsInitialized(getHandlerMethods());
}
```

### 查找HandlerMethod

```java
/**
 * Look for handler methods in the specified handler bean.
 * @param handler either a bean name or an actual handler instance
 * @see #getMappingForMethod
 */
protected void detectHandlerMethods(Object handler) {
   Class<?> handlerType = (handler instanceof String ?
         obtainApplicationContext().getType((String) handler) : handler.getClass());

   if (handlerType != null) {
      Class<?> userType = ClassUtils.getUserClass(handlerType);
      Map<Method, T> methods = MethodIntrospector.selectMethods(userType,
            (MethodIntrospector.MetadataLookup<T>) method -> {
               try {
                  // 如果当前方法有@RequestMapping注解,创建RequestMappingInfo
                  return getMappingForMethod(method, userType);
               }
               catch (Throwable ex) {
                  throw new IllegalStateException("Invalid mapping on handler class [" +
                        userType.getName() + "]: " + method, ex);
               }
            });
      if (logger.isTraceEnabled()) {
         logger.trace(formatMappings(userType, methods));
      }
      methods.forEach((method, mapping) -> {
         Method invocableMethod = AopUtils.selectInvocableMethod(method, userType);
         // 将HandlerMethod注册到MappingRegistry中
         registerHandlerMethod(handler, invocableMethod, mapping);
      });
   }
}
```

## MappingRegistry

AbstractHandlerMethodMapping的内部类，用来注册url到Handler的映射信息的。

## HandlerMethod



### MethodParameter

封装HandlerMethod的参数信息。

#### 获取参数的注解

```java
public Annotation[] getParameterAnnotations() {
   Annotation[] paramAnns = this.parameterAnnotations;
   if (paramAnns == null) {
       // 获取注解
      Annotation[][] annotationArray = this.executable.getParameterAnnotations();
      int index = this.parameterIndex;
      if (this.executable instanceof Constructor &&
            ClassUtils.isInnerClass(this.executable.getDeclaringClass()) &&
            annotationArray.length == this.executable.getParameterCount() - 1) {
         // Bug in javac in JDK <9: annotation array excludes enclosing instance parameter
         // for inner classes, so access it with the actual parameter index lowered by 1
         index = this.parameterIndex - 1;
      }
      paramAnns = (index >= 0 && index < annotationArray.length ?
            adaptAnnotationArray(annotationArray[index]) : EMPTY_ANNOTATION_ARRAY);
      this.parameterAnnotations = paramAnns;
   }
   return paramAnns;
}
```

# 处理@ResponseBody注解

# 寻找handler

# HandlerAdapter

## RequestMappingHandlerAdapter

### 类图

![image-20210206100059215](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210206100059215.png)



# DispatcheServlet

## 处理流程

![image-20210206094652231](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210206094652231.png)

## 检测是否是Multipart请求

```java
/**
 * Convert the request into a multipart request, and make multipart resolver available.
 * <p>If no multipart resolver is set, simply use the existing request.
 * @param request current HTTP request
 * @return the processed request (multipart wrapper if necessary)
 * @see MultipartResolver#resolveMultipart
 */
protected HttpServletRequest checkMultipart(HttpServletRequest request) throws MultipartException {
   // 判断contentType是否是以multipart/开头
   if (this.multipartResolver != null && this.multipartResolver.isMultipart(request)) {
      if (WebUtils.getNativeRequest(request, MultipartHttpServletRequest.class) != null) {
         if (request.getDispatcherType().equals(DispatcherType.REQUEST)) {
            logger.trace("Request already resolved to MultipartHttpServletRequest, e.g. by MultipartFilter");
         }
      }
      else if (hasMultipartException(request)) {
         logger.debug("Multipart resolution previously failed for current request - " +
               "skipping re-resolution for undisturbed error rendering");
      }
      else {
         try {
            // 将request解析成multipart request
            return this.multipartResolver.resolveMultipart(request);
         }
         catch (MultipartException ex) {
            if (request.getAttribute(WebUtils.ERROR_EXCEPTION_ATTRIBUTE) != null) {
               logger.debug("Multipart resolution failed for error dispatch", ex);
               // Keep processing error dispatch with regular request handle below
            }
            else {
               throw ex;
            }
         }
      }
   }
   // If not returned before: return original request.
   return request;
}
```

## 获取Handler

## 获取HandlerAdapter

# 参数解析

## HandlerMethodArgumentResolverComposite

里面持有多个method参数解析器。

## 默认的参数解析器

```java
RequestMappingHandlerAdapter.class
    
private List<HandlerMethodArgumentResolver> getDefaultArgumentResolvers() {
   List<HandlerMethodArgumentResolver> resolvers = new ArrayList<>(30);

   // Annotation-based argument resolution
   resolvers.add(new RequestParamMethodArgumentResolver(getBeanFactory(), false));
   resolvers.add(new RequestParamMapMethodArgumentResolver());
   resolvers.add(new PathVariableMethodArgumentResolver());
   resolvers.add(new PathVariableMapMethodArgumentResolver());
   resolvers.add(new MatrixVariableMethodArgumentResolver());
   resolvers.add(new MatrixVariableMapMethodArgumentResolver());
   resolvers.add(new ServletModelAttributeMethodProcessor(false));
   resolvers.add(new RequestResponseBodyMethodProcessor(getMessageConverters(), this.requestResponseBodyAdvice));
   resolvers.add(new RequestPartMethodArgumentResolver(getMessageConverters(), this.requestResponseBodyAdvice));
   resolvers.add(new RequestHeaderMethodArgumentResolver(getBeanFactory()));
   resolvers.add(new RequestHeaderMapMethodArgumentResolver());
   resolvers.add(new ServletCookieValueMethodArgumentResolver(getBeanFactory()));
   resolvers.add(new ExpressionValueMethodArgumentResolver(getBeanFactory()));
   resolvers.add(new SessionAttributeMethodArgumentResolver());
   resolvers.add(new RequestAttributeMethodArgumentResolver());

   // Type-based argument resolution
   resolvers.add(new ServletRequestMethodArgumentResolver());
   resolvers.add(new ServletResponseMethodArgumentResolver());
   resolvers.add(new HttpEntityMethodProcessor(getMessageConverters(), this.requestResponseBodyAdvice));
   resolvers.add(new RedirectAttributesMethodArgumentResolver());
   resolvers.add(new ModelMethodProcessor());
   resolvers.add(new MapMethodProcessor());
   resolvers.add(new ErrorsMethodArgumentResolver());
   resolvers.add(new SessionStatusMethodArgumentResolver());
   resolvers.add(new UriComponentsBuilderMethodArgumentResolver());

   // Custom arguments
   if (getCustomArgumentResolvers() != null) {
      resolvers.addAll(getCustomArgumentResolvers());
   }

   // Catch-all
    // 上面已经添加了一个RequestParamMethodArgumentResolver，不过第二个参数为false
   resolvers.add(new RequestParamMethodArgumentResolver(getBeanFactory(), true));
   resolvers.add(new ServletModelAttributeMethodProcessor(true));

   return resolvers;
}
```

## RequestParamMethodArgumentResolver

```java
// 是否支持当前的方法
public boolean supportsParameter(MethodParameter parameter) {
    // 有RequestParam注解
   if (parameter.hasParameterAnnotation(RequestParam.class)) {
      if (Map.class.isAssignableFrom(parameter.nestedIfOptional().getNestedParameterType())) {
         RequestParam requestParam = parameter.getParameterAnnotation(RequestParam.class);
         return (requestParam != null && StringUtils.hasText(requestParam.name()));
      }
      else {
         return true;
      }
   }
   else {
      if (parameter.hasParameterAnnotation(RequestPart.class)) {
         return false;
      }
      parameter = parameter.nestedIfOptional();
      if (MultipartResolutionDelegate.isMultipartArgument(parameter)) {
         return true;
      }
       // 使用默认的
      else if (this.useDefaultResolution) {
          // 判断参数类型是否是简单类型
         return BeanUtils.isSimpleProperty(parameter.getNestedParameterType());
      }
      else {
         return false;
      }
   }
}
```

## RequestResponseBodyMethodProcessor

处理RequestBody和ResponseBody注解的。

![image-20210206150210409](C:\Users\ZH1476\AppData\Roaming\Typora\typora-user-images\image-20210206150210409.png)

### EmptyBodyCheckingHttpInputMessage

```java
private static class EmptyBodyCheckingHttpInputMessage implements HttpInputMessage {

   private final HttpHeaders headers;

   @Nullable
   private final InputStream body;

   public EmptyBodyCheckingHttpInputMessage(HttpInputMessage inputMessage) throws IOException {
      this.headers = inputMessage.getHeaders();
      InputStream inputStream = inputMessage.getBody();
      if (inputStream.markSupported()) {
         inputStream.mark(1);
         this.body = (inputStream.read() != -1 ? inputStream : null);
         inputStream.reset();
      }
      else {
         PushbackInputStream pushbackInputStream = new PushbackInputStream(inputStream);
         int b = pushbackInputStream.read();
         // 没有读取到内容，就将body设置为null
         if (b == -1) {
            this.body = null;
         }
         else {
            this.body = pushbackInputStream;
            pushbackInputStream.unread(b);
         }
      }
   }

   @Override
   public HttpHeaders getHeaders() {
      return this.headers;
   }

   @Override
   public InputStream getBody() {
      return (this.body != null ? this.body : StreamUtils.emptyInput());
   }

   public boolean hasBody() {
      return (this.body != null);
   }
}
```

### 读取body

```java
@Override
protected <T> Object readWithMessageConverters(NativeWebRequest webRequest, MethodParameter parameter,
      Type paramType) throws IOException, HttpMediaTypeNotSupportedException, HttpMessageNotReadableException {

   HttpServletRequest servletRequest = webRequest.getNativeRequest(HttpServletRequest.class);
   Assert.state(servletRequest != null, "No HttpServletRequest");
   ServletServerHttpRequest inputMessage = new ServletServerHttpRequest(servletRequest);

   Object arg = readWithMessageConverters(inputMessage, parameter, paramType);
   if (arg == null && checkRequired(parameter)) {
       // 没有读取到就跑出异常
      throw new HttpMessageNotReadableException("Required request body is missing: " +
            parameter.getExecutable().toGenericString(), inputMessage);
   }
   return arg;
}


	protected <T> Object readWithMessageConverters(HttpInputMessage inputMessage, MethodParameter parameter,
			Type targetType) throws IOException, HttpMediaTypeNotSupportedException, HttpMessageNotReadableException {

		MediaType contentType;
		boolean noContentType = false;
		try {
			// 内容类型
			contentType = inputMessage.getHeaders().getContentType();
		}
		catch (InvalidMediaTypeException ex) {
			throw new HttpMediaTypeNotSupportedException(ex.getMessage());
		}
		if (contentType == null) {
			noContentType = true;
			contentType = MediaType.APPLICATION_OCTET_STREAM;
		}

		Class<?> contextClass = parameter.getContainingClass();
		// 参数的类型
		Class<T> targetClass = (targetType instanceof Class ? (Class<T>) targetType : null);
		if (targetClass == null) {
			ResolvableType resolvableType = ResolvableType.forMethodParameter(parameter);
			targetClass = (Class<T>) resolvableType.resolve();
		}

		HttpMethod httpMethod = (inputMessage instanceof HttpRequest ? ((HttpRequest) inputMessage).getMethod() : null);
		Object body = NO_VALUE;

		EmptyBodyCheckingHttpInputMessage message;
		try {
			message = new EmptyBodyCheckingHttpInputMessage(inputMessage);

			for (HttpMessageConverter<?> converter : this.messageConverters) {
				Class<HttpMessageConverter<?>> converterType = (Class<HttpMessageConverter<?>>) converter.getClass();
				GenericHttpMessageConverter<?> genericConverter =
						(converter instanceof GenericHttpMessageConverter ? (GenericHttpMessageConverter<?>) converter : null);
				if (genericConverter != null ? genericConverter.canRead(targetType, contextClass, contentType) :
						(targetClass != null && converter.canRead(targetClass, contentType))) {
					if (message.hasBody()) {
						// 在读取body之前对body中的内容进行处理(比如解密)
						HttpInputMessage msgToUse =
								getAdvice().beforeBodyRead(message, parameter, targetType, converterType);
						// 对body进行转换
						body = (genericConverter != null ? genericConverter.read(targetType, contextClass, msgToUse) :
								((HttpMessageConverter<T>) converter).read(targetClass, msgToUse));
						// 读取body之后对body进行处理
						body = getAdvice().afterBodyRead(body, msgToUse, parameter, targetType, converterType);
					}
					else {
						body = getAdvice().handleEmptyBody(null, message, parameter, targetType, converterType);
					}
					break;
				}
			}
		}
		catch (IOException ex) {
			throw new HttpMessageNotReadableException("I/O error while reading input message", ex, inputMessage);
		}

		if (body == NO_VALUE) {
			if (httpMethod == null || !SUPPORTED_METHODS.contains(httpMethod) ||
					(noContentType && !message.hasBody())) {
				return null;
			}
			throw new HttpMediaTypeNotSupportedException(contentType, this.allSupportedMediaTypes);
		}

		MediaType selectedContentType = contentType;
		Object theBody = body;
		LogFormatUtils.traceDebug(logger, traceOn -> {
			String formatted = LogFormatUtils.formatValue(theBody, !traceOn);
			return "Read \"" + selectedContentType + "\" to [" + formatted + "]";
		});

		return body;
	}
```

#### 对body进行转换

##### MappingJackson2HttpMessageConverter

```java
private Object readJavaType(JavaType javaType, HttpInputMessage inputMessage) throws IOException {
   MediaType contentType = inputMessage.getHeaders().getContentType();
   Charset charset = getCharset(contentType);

   boolean isUnicode = ENCODINGS.containsKey(charset.name());
   try {
      if (inputMessage instanceof MappingJacksonInputMessage) {
         Class<?> deserializationView = ((MappingJacksonInputMessage) inputMessage).getDeserializationView();
         if (deserializationView != null) {
            ObjectReader objectReader = this.objectMapper.readerWithView(deserializationView).forType(javaType);
            if (isUnicode) {
               return objectReader.readValue(inputMessage.getBody());
            }
            else {
               Reader reader = new InputStreamReader(inputMessage.getBody(), charset);
               return objectReader.readValue(reader);
            }
         }
      }
      if (isUnicode) {
         // 直接调用jackson框架中的方法
         return this.objectMapper.readValue(inputMessage.getBody(), javaType);
      }
      else {
         Reader reader = new InputStreamReader(inputMessage.getBody(), charset);
         return this.objectMapper.readValue(reader, javaType);
      }
   }
   catch (InvalidDefinitionException ex) {
      throw new HttpMessageConversionException("Type definition error: " + ex.getType(), ex);
   }
   catch (JsonProcessingException ex) {
      throw new HttpMessageNotReadableException("JSON parse error: " + ex.getOriginalMessage(), ex, inputMessage);
   }
}
```

# 返回值处理

# 获取参数名称

DefaultParameterNameDiscoverer类可以获取到参数名称。

# HttpMessageConverter

# 请求的时候在读取body之前之后对body做处理(比如解密)

直线RequestBodyAdvice接口即可。

```java
@ControllerAdvice// 必须添加，会通过ControllerAdvice注解过滤
public class MyRequestBodyAdvice implements RequestBodyAdvice {
   	/**
	 * 是否支持当前的方法
	 * @param methodParameter the method parameter
	 * @param targetType the target type, not necessarily the same as the method
	 * parameter type, e.g. for {@code HttpEntity<String>}.
	 * @param converterType the selected converter type
	 * @return
	 */
	@Override
	public boolean supports(MethodParameter methodParameter, Type targetType, Class<? extends HttpMessageConverter<?>> converterType) {
		return true;
	}

	/**
	 * 在读取body之前对request中的内容进行处理，比如加密，加密必须要在读取body之前进行解密，
	 * 如果读取了body，那么就会对body的内容进行处理，比如转换成jason或者xml之类的，可能会对
	 * 客户端传过来的数据进行改变，那么此时的内容就和客户端传过来的内容不一致了，所以此时加密并不合适
	 * 一定要在beforeBodyRead方法中解密
	 * @param inputMessage the request
	 * @param parameter the target method parameter
	 * @param targetType the target type, not necessarily the same as the method
	 * parameter type, e.g. for {@code HttpEntity<String>}.
	 * @param converterType the converter used to deserialize the body
	 * @return
	 * @throws IOException
	 */
	@Override
	public HttpInputMessage beforeBodyRead(HttpInputMessage inputMessage, MethodParameter parameter, Type targetType, Class<? extends HttpMessageConverter<?>> converterType) throws IOException {
		return new HttpInputMessage() {
			@Override
			public InputStream getBody() throws IOException {
				HashMap<Object, Object> objectObjectHashMap = Maps.newHashMap();
				objectObjectHashMap.put("name", "xiaoming");
				return new ByteArrayInputStream(JSONUtils.toJSONString(objectObjectHashMap).getBytes());
			}

			@Override
			public HttpHeaders getHeaders() {
				HttpHeaders httpHeaders = new HttpHeaders();
				httpHeaders.setContentType(MediaType.APPLICATION_JSON);
				return httpHeaders;
			}
		};
	}

	/**
	 * 读取body之后再次对body进行处理
	 * @param body set to the converter Object before the first advice is called
	 * @param inputMessage the request
	 * @param parameter the target method parameter
	 * @param targetType the target type, not necessarily the same as the method
	 * parameter type, e.g. for {@code HttpEntity<String>}.
	 * @param converterType the converter used to deserialize the body
	 * @return
	 */
	@Override
	public Object afterBodyRead(Object body, HttpInputMessage inputMessage, MethodParameter parameter, Type targetType, Class<? extends HttpMessageConverter<?>> converterType) {
		return body;
	}

	@Override
	public Object handleEmptyBody(Object body, HttpInputMessage inputMessage, MethodParameter parameter, Type targetType, Class<? extends HttpMessageConverter<?>> converterType) {
		return null;
	}
}
```

# 响应的时候在将内容写入response之前对返回值进行处理

